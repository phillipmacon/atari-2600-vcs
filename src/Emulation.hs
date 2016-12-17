{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE BinaryLiterals #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE Strict #-}

module Emulation(stellaDebug,
                 dumpStella,
                 hpos,
                 vpos,
                 dumpRegisters,
                 dumpState,
                 setBreak,
                 clock,
                 stellaClock,
                 initState,
                 getIRegister,
                 putIRegister,
                 trigger1,
                 modifyIRegister,
                 getORegister) where

--import Data.Monoid
--import Debug.Trace
import Control.Lens
import Control.Monad.State.Strict
import Core
import Data.Data
import Data.Array.IO
import Data.Array.Unboxed
import Metrics
import Data.Bits hiding (bit)
import Data.Bits.Lens
import Memory
import Data.Int
import VideoOps
import Atari2600
import Data.Word
import DebugState
import Disasm
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable
import Numeric
import Prelude hiding (last)
import SDL.Video.Renderer
import Stella.Graphics
import Stella.IntervalTimer
import Stella.SDLState
import Stella.Sprites
import Stella.TIARegisters
import TIAColors
import BitManips
import qualified SDL

initState :: IOUArray Int Word8 ->
             BankMode ->
             IOUArray Int Word8 ->
             IOUArray OReg Word8 ->
             IOUArray IReg Word8 ->
             Word16 ->
             SDL.Surface -> SDL.Surface ->
             SDL.Window -> Atari2600
initState ram' mode rom' oregs iregs initialPC
          helloWorld screenSurface window = Atari2600 {
              _hardware = Hardware {
                  _oregisters = oregs,
                  _iregisters = iregs,
                  _position = (0, 0),
                  _stellaSDL = SDLState {
                      _sdlBackSurface = helloWorld,
                      _sdlFrontSurface = screenSurface,
                      _sdlFrontWindow = window
                  },
                  _sprites = Stella.Sprites.start,
                  _intervalTimer = Stella.IntervalTimer.start,
                  _graphics = Stella.Graphics.start,
                  _stellaClock = 0,
                  _stellaDebug = DebugState.start,
                  _trigger1 = False,
                  _pf = 0
              },
              _memory = Memory {
                  _rom = rom',
                  _ram = ram',
                  _bankMode = mode,
                  _bankOffset = 0
              },
              _clock = 0,
              _regs = R initialPC 0 0 0 0 0xff,
              _debug = 8
          }

{-# INLINE flagC #-}
flagC :: Lens' Registers Bool
flagC = p . bitAt 0

{-# INLINE flagZ #-}
flagZ :: Lens' Registers Bool
flagZ = p . bitAt 1

{-# INLINE flagI #-}
flagI :: Lens' Registers Bool
flagI = p . bitAt 2

{-# INLINE flagD #-}
flagD :: Lens' Registers Bool
flagD = p . bitAt 3

{-# INLINE flagB #-}
flagB :: Lens' Registers Bool
flagB = p . bitAt 4

{-# INLINE flagV #-}
flagV :: Lens' Registers Bool
flagV = p . bitAt 6

{-# INLINE flagN #-}
flagN :: Lens' Registers Bool
flagN = p . bitAt 7

{-# INLINE putORegister #-}
putORegister :: OReg -> Word8 -> MonadAtari ()
putORegister i v = do
    r <- use (hardware . oregisters)
    liftIO $ writeArray r i v

{-# INLINE getORegister #-}
getORegister :: OReg -> MonadAtari Word8
getORegister i = do
    r <- use (hardware . oregisters)
    liftIO $ readArray r i

{-# INLINE putIRegister #-}
putIRegister :: IReg -> Word8 -> MonadAtari ()
putIRegister i v = do
    r <- use (hardware . iregisters)
    liftIO $ writeArray r i v

{-# INLINE modifyIRegister #-}
modifyIRegister :: IReg -> (Word8 -> Word8) -> MonadAtari ()
modifyIRegister i f = do
    r <- use (hardware . iregisters)
    liftIO $ (readArray r i >>= writeArray r i . f)

{-# INLINE getIRegister #-}
getIRegister :: IReg -> MonadAtari Word8
getIRegister i = do
    r <- use (hardware . iregisters)
    liftIO $ readArray r i

{-# INLINE orIRegister #-}
orIRegister :: IReg -> Word8 -> MonadAtari ()
orIRegister i v = modifyIRegister i (v .|.)

{- INLINE stellaHmclr -}
stellaHmclr :: MyState Hardware ()
stellaHmclr = do
    r <- use oregisters
    liftIO $ mapM_ (flip (fastPutORegister r) 0) [hmp0, hmp1,
                                                  hmm0, hmm1, hmbl]

{- INLINE stellaCxclr -}
stellaCxclr :: MyState Hardware ()
stellaCxclr = do
    r <- use iregisters
    liftIO $ mapM_ (flip (fastPutIRegister r) 0) [cxm0p, cxm1p, cxm0fb,
                                                  cxm1fb, cxp0fb, cxp1fb,
                                                  cxblpf, cxppmm]

{- INLINE stellaHmove -}
stellaHmove :: MyState Hardware ()
stellaHmove = do
    Sprites !ppos0' !ppos1' !mpos0' !mpos1' !bpos' <- use sprites

    !r <- use oregisters
    let getOReg !reg = liftIO $ fastGetORegister r reg

    !poffset0 <- getOReg hmp0
    let !ppos0'' = wrap160 (ppos0'-clockMove poffset0)

    !poffset1 <- getOReg hmp1
    let !ppos1'' = wrap160 (ppos1'-clockMove poffset1)

    !moffset0 <- getOReg hmm0
    let !mpos0'' = wrap160 (mpos0'-clockMove moffset0) -- XXX do rest

    !moffset1 <- getOReg hmm1
    let !mpos1'' = wrap160 (mpos1'-clockMove moffset1) -- XXX do rest

    !boffset <- getOReg hmbl
    let !bpos'' = wrap160 (bpos'-clockMove boffset)

    sprites .= Sprites {
        _s_ppos0 = ppos0'',
        _s_ppos1 = ppos1'',
        _s_mpos0 = mpos0'',
        _s_mpos1 = mpos1'',
        _s_bpos = bpos''
    }

{- INLINE stellaResmp0 -}
stellaResmp0 ::  MonadAtari ()
stellaResmp0 = use ppos0 >>= (mpos0 .=) -- XXX

{- INLINE stellaResmp1 -}
stellaResmp1 :: MonadAtari ()
stellaResmp1 = use ppos1 >>= (mpos1 .=) -- XXX

inBinary :: (Bits a) => Int -> a -> String
inBinary 0 _ = ""
inBinary n m = inBinary (n-1) (m `shift` (-1)) ++ if testBit m 0 then "1" else "0"

explainNusiz :: Word8 -> String
explainNusiz nusiz =
    case nusiz .&. 0b111 of
        0b000 -> "one copy"
        0b001 -> "two copies - close"
        0b010 -> "two copies - med"
        0b011 -> "three copies - close"
        0b100 -> "two copies - wide"
        0b101 -> "double size player"
        0b110 -> "3 copies medium"
        0b111 -> "quad sized player"
        _ -> error "Impossible to reach"

{- INLINE stellaDebugStr -}
stellaDebugStr :: Int -> String -> MonadAtari ()
stellaDebugStr n str = do
    d <- use (hardware . stellaDebug . debugLevel)
    if n <= d
        then do
            liftIO $ putStr str
        else return ()

{- INLINE stellaDebugStrLn -}
stellaDebugStrLn :: Int -> String -> MonadAtari ()
stellaDebugStrLn n str = do
    d <- use (hardware . stellaDebug . debugLevel)
    if n <= d
        then do
            liftIO $ putStrLn str
        else return ()

{-# INLINE wrap160 #-}
wrap160 :: Int -> Int
wrap160 i | i < picx = wrap160 (i+160)
          | i >= picx+160 = wrap160 (i-160)
wrap160 i = i

{-# INLINE clockMove #-}
clockMove :: Word8 -> Int
clockMove i = fromIntegral ((fromIntegral i :: Int8) `shift` (-4))

{-# INLINE i8 #-}
i8 :: Integral a => a -> Word8
i8 = fromIntegral

{-# INLINE i16 #-}
i16 :: Integral a => a -> Word16
i16 = fromIntegral

{-# INLINE iz #-}
iz :: Word16 -> Int -- or NUM
iz = fromIntegral

{-
Here's a standard kernel:
StartOfFrame
        ;--------------------------------------------------
        ; Start of vertical blank processing
        ;--------------------------------------------------
                lda #0
                sta VBLANK

                lda #2
                sta VSYNC

                sta WSYNC
                sta WSYNC
                sta WSYNC                ; 3 scanlines of VSYNC signal

                lda #0
                sta VSYNC
        ;--------------------------------------------------
        ; 37 scanlines of vertical blank...
        ;--------------------------------------------------
                ldx #0
VerticalBlank   sta WSYNC
                inx
                cpx #37
                bne VerticalBlank
        ;--------------------------------------------------
        ; Do 192 scanlines of colour-changing (our picture)
        ;--------------------------------------------------
                ldx #0                  ; this counts our scanline number
                ...
Lines           sta WSYNC
                inx
                cpx #192
                bne Lines
        ;--------------------------------------------------
        ; 30 scanlines of overscan...
        ;--------------------------------------------------
                lda #%01000010
                sta VBLANK           ; end of screen - enter blanking

                ldx #0
Overscan        sta WSYNC
                inx
                cpx #30
                bne Overscan

                jmp StartOfFrame
-}

{- INLINE stellaVblank -}
stellaVblank :: Word8 -> MyState Hardware ()
stellaVblank v = do
    ir <- use iregisters
    or <- use oregisters
    trigger <- use trigger1
    if not trigger
        then do
            i <- liftIO $ fastGetIRegister ir inpt4 -- XXX write modifyIRegister
            liftIO $ fastPutIRegister ir inpt4 (setBit i 7)
        else do
            i <- liftIO $ fastGetIRegister ir inpt4 -- XXX write modifyIRegister
            liftIO $ fastPutIRegister ir inpt4 (clearBit i 7)

    liftIO $ fastPutORegister or vblank v

{-# INLINE hpos #-}
{-# INLINE vpos #-}
hpos, vpos :: Lens' Atari2600 Int
hpos = hardware . position . _1
vpos = hardware . position . _2

{-# INLINE ppos0 #-}
{-# INLINE ppos1 #-}
{-# INLINE mpos0 #-}
{-# INLINE mpos1 #-}
{-# INLINE bpos #-}
ppos0, ppos1, mpos0, mpos1, bpos :: Lens' Atari2600 Int
ppos0 = hardware . sprites . s_ppos0
ppos1 = hardware . sprites . s_ppos1
mpos0 = hardware . sprites . s_mpos0
mpos1 = hardware . sprites . s_mpos1
bpos = hardware . sprites . s_bpos

makePlayfield :: MonadAtari ()
makePlayfield = do
    r <- use (hardware . oregisters)
    !pf0' <- liftIO $ fastGetORegister r pf0
    !pf1' <- liftIO $ fastGetORegister r pf1
    !pf2' <- liftIO $ fastGetORegister r pf2
    !ctrlpf' <- liftIO $ fastGetORegister r ctrlpf
    let !pf' = assemblePlayfield (testBit ctrlpf' 0) pf0' pf1' pf2'
    hardware . pf .= pf'

{- INLINABLE readStella -}
readStella :: Word16 -> MonadAtari Word8
readStella addr = 
    case addr of
        0x00 -> getIRegister cxm0p
        0x01 -> getIRegister cxm1p
        0x02 -> getIRegister cxp0fb
        0x03 -> getIRegister cxp1fb
        0x04 -> getIRegister cxm0fb
        0x05 -> getIRegister cxm1fb
        0x06 -> getIRegister cxblpf
        0x07 -> getIRegister cxppmm
        0x0c -> getIRegister inpt4
        0x0d -> getIRegister inpt5
        0x10 -> getIRegister cxm0p
        0x11 -> getIRegister cxm1p
        0x12 -> getIRegister cxp0fb
        0x13 -> getIRegister cxp1fb
        0x14 -> getIRegister cxm0fb
        0x15 -> getIRegister cxm1fb
        0x16 -> getIRegister cxblpf
        0x17 -> getIRegister cxppmm
        0x1c -> getIRegister inpt4
        0x1d -> getIRegister inpt5
        0x20 -> getIRegister cxm0p
        0x21 -> getIRegister cxm1p
        0x22 -> getIRegister cxp0fb
        0x23 -> getIRegister cxp1fb
        0x24 -> getIRegister cxm0fb
        0x25 -> getIRegister cxm1fb
        0x26 -> getIRegister cxblpf
        0x27 -> getIRegister cxppmm
        0x2c -> getIRegister inpt4
        0x2d -> getIRegister inpt5
        0x30 -> getIRegister cxm0p
        0x31 -> getIRegister cxm1p
        0x32 -> getIRegister cxp0fb
        0x33 -> getIRegister cxp1fb
        0x34 -> getIRegister cxm0fb
        0x35 -> getIRegister cxm1fb
        0x36 -> getIRegister cxblpf
        0x37 -> getIRegister cxppmm
        0x3c -> getIRegister inpt4
        0x3d -> getIRegister inpt5
        0x280 -> getIRegister swcha
        0x282 -> getIRegister swchb
        0x284 -> use (hardware . intervalTimer . intim)
        _ -> return 0 -- (liftIO $ putStrLn $ "reading TIA 0x" ++ showHex addr "") >> return 0

{- INLINE stellaVsync -}
stellaVsync :: Word8 -> MyState Hardware ()
stellaVsync v = do
    or <- use oregisters
    oldv <- liftIO $ fastGetORegister or vsync
    when (testBit oldv 1 && not (testBit v 1)) $ position .= (0, 0)
    liftIO $ fastPutORegister or vsync v
    sdlState <- use stellaSDL
    liftIO $ renderDisplay sdlState

{- INLINE stellaWsync -}
stellaWsync :: MonadAtari ()
stellaWsync = do
    hpos' <- use hpos
    when (hpos' > 2) $ do
        clock += 1 -- sleep the CPU
        clock' <- use clock
        zoomHardware $ stellaTickUntil (3*clock')
        stellaWsync

-- http://atariage.com/forums/topic/107527-atari-2600-vsyncvblank/

{-# INLINE church #-}
church 0 f x = x
church n f x = church (n-1) f (f x)

stellaTickUntil :: Int64 -> MyState Hardware ()
stellaTickUntil n = do
    !c <- use stellaClock
    let !diff = n-c
    when (diff >= 0) $ do
        -- Batch together items that don't need to be
        -- carried out on individual ticks
        stellaClock += diff
        !it <- use intervalTimer
        intervalTimer .= church diff timerTick it
        r <- use oregisters
        resmp0' <- liftIO $ fastGetORegister r resmp0
        resmp1' <- liftIO $ fastGetORegister r resmp1
        sprites %= clampMissiles resmp0' resmp1'

        hardware' <- get
        surface <- use (stellaSDL . sdlBackSurface)
        !ptr <- liftIO $ surfacePixels surface
        let !ptr' = castPtr ptr :: Ptr Word32
        hardware'' <- liftIO $ stellaTick (fromIntegral diff) hardware' ptr'
        put hardware''

{-# INLINE pureReadRom #-}
pureReadRom :: Word16 -> MyState Memory Word8
pureReadRom addr = do
    m <- use rom
    offset <- use bankOffset
    !byte <- liftIO $ readArray m ((iz addr .&. 0xfff)+fromIntegral offset)
    return byte

{-# INLINE bankSwitch #-}
bankSwitch :: BankMode -> Word16 -> Word16 -> Word16
bankSwitch _        !addr  !old | addr < 0x1ff6 = old
bankSwitch UnBanked _      _    = 0
bankSwitch F8       0x1ff8 _    = 0
bankSwitch F8       0x1ff9 _    = 0x1000
bankSwitch F6       0x1ff6 _    = 0
bankSwitch F6       0x1ff7 _    = 0x1000
bankSwitch F6       0x1ff8 _    = 0x2000
bankSwitch F6       0x1ff9 _    = 0x3000
bankSwitch _        _      !old = old

{-# INLINE pureReadMemory #-}
pureReadMemory :: Word16 -> MonadAtari Word8
pureReadMemory addr | addr >= 0x1000 = zoomMemory $ pureReadRom addr
pureReadMemory addr | isRAM addr = do
    m <- use (memory . ram)
    liftIO $ readArray m (iz addr .&. 0x7f)
pureReadMemory addr | isTIA addr     = readStella (addr .&. 0x3f)
pureReadMemory addr | isRIOT addr    = readStella (0x280+(addr .&. 0x1f))
pureReadMemory _                     = error $ "The cases were exhaustive :-("

{-# INLINE pureWriteMemory #-}
pureWriteMemory :: Word16 -> Word8 -> MonadAtari ()
pureWriteMemory addr v = do
    if isRAM addr
        then do
            m <- use (memory . ram)
            liftIO $ writeArray m (iz addr .&. 0x7f) v
        else if isTIA addr
            then writeStella (addr .&. 0x3f) v
            else if isRIOT addr
                    then writeStella (0x280+(addr .&. 0x1f)) v
                    else return () -- ROM

instance Emu6502 MonadAtari where
    {-# INLINE readMemory #-}
    readMemory addr' = do
        let addr = addr' .&. 0x1fff -- 6507
        byte <- pureReadMemory addr
        bankType <- use (memory . bankMode)
        memory . bankOffset %= bankSwitch bankType addr
        return byte

    {-# INLINE writeMemory #-}
    writeMemory addr' v = do
        let addr = addr' .&. 0x1fff -- 6507
        pureWriteMemory addr v
        bankType <- use (memory . bankMode)
        memory . bankOffset %= bankSwitch bankType addr

    {-# INLINE getPC #-}
    getPC = use (regs . pc)
    {-# INLINE tick #-}
    tick n = do
        clock += fromIntegral n
        c <- use clock
        zoomHardware $ stellaTickUntil (3*c)
    {-# INLINE putC #-}
    putC b = regs . flagC .= b
    {-# INLINE getC #-}
    getC = use (regs . flagC)
    {-# INLINE putZ #-}
    putZ b = regs . flagZ .= b
    {-# INLINE getZ #-}
    getZ = use (regs . flagZ)
    {-# INLINE putI #-}
    putI b = regs . flagI .= b
    {-# INLINE getI #-}
    getI = use (regs . flagI)
    {-# INLINE putD #-}
    putD b = regs . flagD .= b
    {-# INLINE getD #-}
    getD = use (regs . flagD)
    {-# INLINE putB #-}
    putB b = regs . flagB .= b
    {-# INLINE getB #-}
    getB = use (regs . flagB)
    {-# INLINE putV #-}
    putV b = regs . flagV .= b
    {-# INLINE getV #-}
    getV = use (regs . flagV)
    {-# INLINE putN #-}
    putN b = regs . flagN .= b
    {-# INLINE getN #-}
    getN = use (regs . flagN)
    {-# INLINE getA #-}
    getA = use (regs . a)
    {-# INLINE putA #-}
    putA r = regs . a .= r
    {-# INLINE getS #-}
    getS = use (regs . s)
    {-# INLINE putS #-}
    putS r = regs . s .= r
    {-# INLINE getX #-}
    getX = use (regs . x)
    {-# INLINE putX #-}
    putX r = regs . x .= r
    {-# INLINE getP #-}
    getP = use (regs . p)
    {-# INLINE putP #-}
    putP r = regs . p .= r
    {-# INLINE getY #-}
    getY = use (regs . y)
    {-# INLINE putY #-}
    putY r = regs . y .= r
    {-# INLINE putPC #-}
    putPC r = regs . pc .= r
    {-# INLINE addPC #-}
    addPC n = regs . pc += fromIntegral n

    {-# INLINE debugStr #-}
    debugStr _ _ = return ()
    {-# INLINE debugStrLn #-}
    debugStrLn _ _ = return ()

{-
    {- INLINE debugStr 9 -}
    debugStr n str = do
        d <- use debug
        if n <= d
            then liftIO $ putStr str
            else return ()

    {- INLINE debugStrLn 9 -}
    debugStrLn n str = do
        d <- use debug
        if n <= d
            then liftIO $ putStrLn str
            else return ()
-}

    {- INLINE illegal -}
    illegal i = error $ "Illegal opcode 0x" ++ showHex i ""

dumpStella :: MonadAtari ()
dumpStella = do
    liftIO $ putStrLn "--------"
    hpos' <- use hpos
    vpos' <- use vpos
    liftIO $ putStrLn $ "hpos = " ++ show hpos' ++ " (" ++ show (hpos'-picx) ++ ") vpos = " ++ show vpos' ++ " (" ++ show (vpos'-picy) ++ ")"
    grp0' <- use (hardware . graphics . oldGrp0) -- XXX
    grp1' <- use (hardware . graphics . oldGrp1) -- XXX
    liftIO $ putStrLn $ "GRP0 = " ++ showHex grp0' "" ++ "(" ++ inBinary 8 grp0' ++ ")"
    liftIO $ putStrLn $ "GRP1 = " ++ showHex grp1' "" ++ "(" ++ inBinary 8 grp1' ++ ")"
    pf0' <- getORegister pf0
    pf1' <- getORegister pf1
    pf2' <- getORegister pf2
    liftIO $ putStrLn $ "PF = " ++ reverse (inBinary 4 (pf0' `shift` (-4)))
                                ++ inBinary 8 pf1'
                                ++ reverse (inBinary 8 pf2')
    nusiz0' <- getORegister nusiz0
    nusiz1' <- getORegister nusiz1
    liftIO $ putStrLn $ "NUSIZ0 = " ++ showHex nusiz0' "" ++ "(" ++ explainNusiz nusiz0' ++
                        ") NUSIZ1 = " ++ showHex nusiz1' "" ++ "(" ++ explainNusiz nusiz1' ++ ")"
    enam0' <- getORegister enam0
    enam1' <- getORegister enam1
    enablOld <- use (hardware . graphics . oldBall)
    enablNew <- use (hardware . graphics . newBall)
    liftIO $ putStr $ "ENAM0 = " ++ show (testBit enam0' 1)
    liftIO $ putStr $ " ENAM1 = " ++ show (testBit enam1' 1)
    liftIO $ putStrLn $ " ENABL = " ++ show (enablOld, enablNew)
    mpos0' <- use mpos0
    mpos1' <- use mpos1
    hmm0' <- getORegister hmm0
    hmm1' <- getORegister hmm1
    liftIO $ putStr $ "missile0 @ " ++ show mpos0' ++ "(" ++ show (clockMove hmm0') ++ ")"
    liftIO $ putStrLn $ " missile1 @ " ++ show mpos1' ++ "(" ++ show (clockMove hmm1') ++ ")"
    vdelp0' <- use (hardware . graphics . delayP0)
    vdelp1' <- use (hardware . graphics . delayP1)
    vdelbl' <- use (hardware . graphics . delayBall)
    liftIO $ putStrLn $ "VDELP0 = " ++ show vdelp0' ++ " " ++
                        "VDELP1 = " ++ show vdelp1' ++ " " ++
                        "VDELBL = " ++ show vdelbl'

{-# INLINABLE dumpMemory #-}
dumpMemory :: MonadAtari ()
dumpMemory = do
    regPC <- getPC
    b0 <- readMemory regPC
    b1 <- readMemory (regPC+1)
    b2 <- readMemory (regPC+2)
    liftIO $ putStr $ "(PC) = "
    liftIO $ putStr $ showHex b0 "" ++ " "
    liftIO $ putStr $ showHex b1 "" ++ " "
    liftIO $ putStrLn $ showHex b2 ""
    let (_, mne, _) = disasm regPC [b0, b1, b2]
    liftIO $ putStrLn $ mne

{-# INLINABLE dumpRegisters #-}
dumpRegisters :: MonadAtari ()
dumpRegisters = do
    -- XXX bring clock back
    --tClock <- use clock
    --putStr 9 $ "clock = " ++ show tClock
    regPC <- getPC
    liftIO $ putStr $ " pc = " ++ showHex regPC ""
    regP <- getP
    liftIO $ putStr $ " flags = " ++ showHex regP ""
    liftIO $ putStr $ "(N=" ++ showHex ((regP `shift` (-7)) .&. 1) ""
    liftIO $ putStr $ ",V=" ++ showHex ((regP `shift` (-6)) .&. 1) ""
    liftIO $ putStr $ ",B=" ++ showHex (regP `shift` ((-4)) .&. 1) ""
    liftIO $ putStr $ ",D=" ++ showHex (regP `shift` ((-3)) .&. 1) ""
    liftIO $ putStr $ ",I=" ++ showHex (regP `shift` ((-2)) .&. 1) ""
    liftIO $ putStr $ ",Z=" ++ showHex (regP `shift` ((-1)) .&. 1) ""
    liftIO $ putStr $ ",C=" ++ showHex (regP .&. 1) ""
    regA <- getA 
    liftIO $ putStr $ ") A = " ++ showHex regA ""
    regX <- getX
    liftIO $ putStr $ " X = " ++ showHex regX ""
    regY <- getY
    liftIO $ putStrLn $ " Y = " ++ showHex regY ""
    regS <- getS
    liftIO $ putStrLn $ " N = " ++ showHex regS ""

{-# INLINABLE dumpState #-}
dumpState :: MonadAtari ()
dumpState = do
    dumpMemory
    dumpRegisters

{- INLINE setBreak -}
setBreak :: Int -> Int -> MonadAtari ()
setBreak breakX breakY = hardware . stellaDebug . posbreak .= (breakX+picx, breakY+picy)

graphicsDelay :: Int64 -> MonadAtari ()
graphicsDelay n = do
    c <- use clock
    zoomHardware $ stellaTickUntil (3*c+n)

{- INLINABLE writeStella -}
writeStella :: Word16 -> Word8 -> MonadAtari ()
writeStella addr v = 
    case addr of
       0x00 -> zoomHardware $ stellaVsync v             -- VSYNC
       0x01 -> zoomHardware $ stellaVblank v            -- VBLANK
       0x02 -> stellaWsync               -- WSYNC
       0x04 -> putORegister nusiz0 v        -- NUSIZ0
       0x05 -> putORegister nusiz1 v        -- NUSIZ1
       0x06 -> putORegister colup0 v               -- COLUP0
       0x07 -> putORegister colup1 v               -- COLUP1
       0x08 -> putORegister colupf v               -- COLUPF
       0x09 -> putORegister colubk v               -- COLUBK
       0x0a -> putORegister ctrlpf v >> makePlayfield               -- COLUPF
       0x0b -> putORegister refp0 v               -- REFP0
       0x0c -> putORegister refp1 v               -- REFP1
       0x0d -> graphicsDelay 4 >> putORegister pf0 v >> makePlayfield                  -- PF0
       0x0e -> graphicsDelay 4 >> putORegister pf1 v >> makePlayfield                  -- PF1
       0x0f -> graphicsDelay 4 >> putORegister pf2 v >> makePlayfield                  -- PF2
       0x10 -> graphicsDelay 5 >> use hpos >>= (ppos0 .=)   -- RESP0
       0x11 -> graphicsDelay 5 >> use hpos >>= (ppos1 .=)   -- RESP1
       0x12 -> graphicsDelay 4 >> use hpos >>= (mpos0 .=)   -- RESM0
       0x13 -> graphicsDelay 4 >> use hpos >>= (mpos1 .=)   -- RESM1
       0x14 -> graphicsDelay 4 >> use hpos >>= (bpos .=)     -- RESBL
       0x1b -> do -- GRP0
                hardware . graphics . newGrp0 .= v
                use (hardware . graphics . newGrp1) >>= (hardware . graphics . oldGrp1 .=)
       0x1c -> do -- GRP1
                hardware . graphics . newGrp1 .= v
                use (hardware . graphics . newGrp0) >>= (hardware . graphics . oldGrp0 .=)
                use (hardware . graphics . newBall) >>= (hardware . graphics . oldBall .=)
       0x1d -> putORegister enam0 v                -- ENAM0
       0x1e -> putORegister enam1 v                -- ENAM1
       0x1f -> hardware . graphics . newBall .= testBit v 1   -- ENABL
       0x20 -> putORegister hmp0 v                 -- HMP0
       0x21 -> putORegister hmp1 v                 -- HMP1
       0x22 -> putORegister hmm0 v                 -- HMM0
       0x23 -> putORegister hmm1 v                 -- HMM1
       0x24 -> putORegister hmbl v                 -- HMBL
       0x25 -> hardware . graphics . delayP0 .= testBit v 0   -- VDELP0
       0x26 -> hardware . graphics . delayP1 .= testBit v 0   -- VDELP1
       0x27 -> hardware . graphics . delayBall .= testBit v 0   -- VDELBL
       0x28 -> putORegister resmp0 v
       0x29 -> putORegister resmp1 v
       0x2a -> zoomHardware $ stellaHmove               -- HMOVE
       0x2b -> zoomHardware $ stellaHmclr               -- HMCLR
       0x2c -> zoomHardware $ stellaCxclr               -- CXCLR
       0x294 -> hardware . intervalTimer .= start1 v -- TIM1T
       0x295 -> hardware . intervalTimer .= start8 v -- TIM8T
       0x296 -> hardware . intervalTimer .= start64 v -- TIM64T
       0x297 -> hardware . intervalTimer .= start1024 v -- TIM1024T
       _ -> return () -- liftIO $ putStrLn $ "writing TIA 0x" ++ showHex addr ""