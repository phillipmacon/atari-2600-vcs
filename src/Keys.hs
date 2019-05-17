module Keys where

--import Data.Maybe
import Debug.Trace
import SDL.Input.Keyboard
import qualified Data.Map.Strict as M

keyNames :: [(String, Scancode)]
keyNames = [
        ("Unknown", ScancodeUnknown),
        ("A", ScancodeA), ("B", ScancodeB), ("C", ScancodeC), ("D", ScancodeD),
        ("E", ScancodeE), ("F", ScancodeF), ("G", ScancodeG), ("H", ScancodeH),
        ("I", ScancodeI), ("J", ScancodeJ), ("K", ScancodeK), ("L", ScancodeL),
        ("M", ScancodeM), ("N", ScancodeN), ("O", ScancodeO), ("P", ScancodeP),
        ("Q", ScancodeQ), ("R", ScancodeR), ("S", ScancodeS), ("T", ScancodeT),
        ("U", ScancodeU), ("V", ScancodeV), ("W", ScancodeW), ("X", ScancodeX),
        ("Y", ScancodeY), ("Z", ScancodeZ), ("1", Scancode1), ("2", Scancode2),
        ("3", Scancode3), ("4", Scancode4), ("5", Scancode5), ("6", Scancode6),
        ("7", Scancode7), ("8", Scancode8), ("9", Scancode9), ("0", Scancode0),
        ("Return", ScancodeReturn),
        ("Escape", ScancodeEscape),
        ("Backspace", ScancodeBackspace),
        ("Tab", ScancodeTab),
        ("Space", ScancodeSpace),
        ("Minus", ScancodeMinus),
        ("Equals", ScancodeEquals),
        ("LeftBracket", ScancodeLeftBracket),
        ("RightBracket", ScancodeRightBracket),
        ("Backslash", ScancodeBackslash),
        ("NonUSHash", ScancodeNonUSHash),
        ("Semicolon", ScancodeSemicolon),
        ("Apostrophe", ScancodeApostrophe),
        ("Grave", ScancodeGrave),
        ("Comma", ScancodeComma),
        ("Period", ScancodePeriod),
        ("Slash", ScancodeSlash),
        ("CapsLock", ScancodeCapsLock),
        ("F1", ScancodeF1), ("F2", ScancodeF2), ("F3", ScancodeF3), ("F4", ScancodeF4),
        ("F5", ScancodeF5), ("F6", ScancodeF6), ("F7", ScancodeF7), ("F8", ScancodeF8),
        ("F9", ScancodeF9), ("F10", ScancodeF10), ("F11", ScancodeF11), ("F12", ScancodeF12),
        ("PrintScreen", ScancodePrintScreen),
        ("ScrollLock", ScancodeScrollLock),
        ("Pause", ScancodePause),
        ("Insert", ScancodeInsert),
        ("Home", ScancodeHome),
        ("PageUp", ScancodePageUp),
        ("Delete", ScancodeDelete),
        ("End", ScancodeEnd),
        ("PageDown", ScancodePageDown),
        ("Right", ScancodeRight),
        ("Left", ScancodeLeft),
        ("Down", ScancodeDown),
        ("Up", ScancodeUp),
        ("NumLockClear", ScancodeNumLockClear),
        ("KPDivide", ScancodeKPDivide),
        ("KPMultiply", ScancodeKPMultiply),
        ("KPMinus", ScancodeKPMinus),
        ("KPPlus", ScancodeKPPlus),
        ("KPEnter", ScancodeKPEnter),
        ("KP1", ScancodeKP1), ("KP2", ScancodeKP2), ("KP3", ScancodeKP3), ("KP4", ScancodeKP4),
        ("KP5", ScancodeKP5), ("KP6", ScancodeKP6), ("KP7", ScancodeKP7), ("KP8", ScancodeKP8),
        ("KP9", ScancodeKP9), ("KP0", ScancodeKP0),
        ("KPPeriod", ScancodeKPPeriod),
        ("NonUSBackslash", ScancodeNonUSBackslash),
        ("Application", ScancodeApplication),
        ("Power", ScancodePower),
        ("KPEquals", ScancodeKPEquals),
        ("F13", ScancodeF13), ("F14", ScancodeF14), ("F15", ScancodeF15), ("F16", ScancodeF16),
        ("F17", ScancodeF17), ("F18", ScancodeF18), ("F19", ScancodeF19), ("F20", ScancodeF20),
        ("F21", ScancodeF21), ("F22", ScancodeF22), ("F23", ScancodeF23), ("F24", ScancodeF24),
        ("Execute", ScancodeExecute),
        ("Help", ScancodeHelp),
        ("Menu", ScancodeMenu),
        ("Select", ScancodeSelect),
        ("Stop", ScancodeStop),
        ("Again", ScancodeAgain),
        ("Undo", ScancodeUndo),
        ("Cut", ScancodeCut),
        ("Copy", ScancodeCopy),
        ("Paste", ScancodePaste),
        ("Find", ScancodeFind),
        ("Mute", ScancodeMute),
        ("VolumeUp", ScancodeVolumeUp),
        ("VolumeDown", ScancodeVolumeDown),
        ("KPComma", ScancodeKPComma),
        ("KPEqualsAS400", ScancodeKPEqualsAS400),
        ("International1", ScancodeInternational1), ("International2", ScancodeInternational2),
        ("International3", ScancodeInternational3), ("International4", ScancodeInternational4),
        ("International5", ScancodeInternational5), ("International6", ScancodeInternational6),
        ("International7", ScancodeInternational7), ("International8", ScancodeInternational8),
        ("International9", ScancodeInternational9), ("Lang1", ScancodeLang1),
        ("Lang2", ScancodeLang2), ("Lang3", ScancodeLang3),
        ("Lang4", ScancodeLang4), ("Lang5", ScancodeLang5),
        ("Lang6", ScancodeLang6), ("Lang7", ScancodeLang7),
        ("Lang8", ScancodeLang8), ("Lang9", ScancodeLang9),
        ("AltErase", ScancodeAltErase),
        ("SysReq", ScancodeSysReq),
        ("Cancel", ScancodeCancel),
        ("Clear", ScancodeClear),
        ("Prior", ScancodePrior),
        ("Return2", ScancodeReturn2),
        ("Separator", ScancodeSeparator),
        ("Out", ScancodeOut),
        ("Oper", ScancodeOper),
        ("ClearAgain", ScancodeClearAgain),
        ("CrSel", ScancodeCrSel),
        ("ExSel", ScancodeExSel),
        ("KP00", ScancodeKP00),
        ("KP000", ScancodeKP000),
        ("ThousandsSeparator", ScancodeThousandsSeparator),
        ("DecimalSeparator", ScancodeDecimalSeparator),
        ("CurrencyUnit", ScancodeCurrencyUnit),
        ("CurrencySubunit", ScancodeCurrencySubunit),
        ("LeftParen", ScancodeLeftParen),
        ("RightParen", ScancodeRightParen),
        ("LeftBrace", ScancodeLeftBrace),
        ("RightBrace", ScancodeRightBrace),
        ("KPTab", ScancodeKPTab),
        ("KPBackspace", ScancodeKPBackspace),
        ("KPA", ScancodeKPA), ("KPB", ScancodeKPB), ("KPC", ScancodeKPC), ("KPD", ScancodeKPD),
        ("KPE", ScancodeKPE), ("KPF", ScancodeKPF),
        ("KPXOR", ScancodeKPXOR),
        ("KPPower", ScancodeKPPower),
        ("KPPercent", ScancodeKPPercent),
        ("KPLess", ScancodeKPLess),
        ("KPGreater", ScancodeKPGreater),
        ("KPAmpersand", ScancodeKPAmpersand),
        ("KPDblAmpersand", ScancodeKPDblAmpersand),
        ("KPVerticalBar", ScancodeKPVerticalBar),
        ("KPDblVerticalBar", ScancodeKPDblVerticalBar),
        ("KPColon", ScancodeKPColon),
        ("KPHash", ScancodeKPHash),
        ("KPSpace", ScancodeKPSpace),
        ("KPAt", ScancodeKPAt),
        ("KPExclam", ScancodeKPExclam),
        ("KPMemStore", ScancodeKPMemStore),
        ("KPMemRecall", ScancodeKPMemRecall),
        ("KPMemClear", ScancodeKPMemClear),
        ("KPMemAdd", ScancodeKPMemAdd),
        ("KPMemSubtract", ScancodeKPMemSubtract),
        ("KPMemMultiply", ScancodeKPMemMultiply),
        ("KPMemDivide", ScancodeKPMemDivide),
        ("KPPlusMinus", ScancodeKPPlusMinus),
        ("KPClear", ScancodeKPClear),
        ("KPClearEntry", ScancodeKPClearEntry),
        ("KPBinary", ScancodeKPBinary),
        ("KPOctal", ScancodeKPOctal),
        ("KPDecimal", ScancodeKPDecimal),
        ("KPHexadecimal", ScancodeKPHexadecimal),
        ("LCtrl", ScancodeLCtrl),
        ("LShift", ScancodeLShift),
        ("LAlt", ScancodeLAlt),
        ("LGUI", ScancodeLGUI),
        ("RCtrl", ScancodeRCtrl),
        ("RShift", ScancodeRShift),
        ("RAlt", ScancodeRAlt),
        ("RGUI", ScancodeRGUI),
        ("Mode", ScancodeMode),
        ("AudioNext", ScancodeAudioNext), ("AudioPrev", ScancodeAudioPrev),
        ("AudioStop", ScancodeAudioStop), ("AudioPlay", ScancodeAudioPlay),
        ("AudioMute", ScancodeAudioMute), ("MediaSelect", ScancodeMediaSelect),
        ("WWW", ScancodeWWW),
        ("Mail", ScancodeMail),
        ("Calculator", ScancodeCalculator),
        ("Computer", ScancodeComputer),
        ("ACSearch", ScancodeACSearch),
        ("ACHome", ScancodeACHome),
        ("ACBack", ScancodeACBack),
        ("ACForward", ScancodeACForward),
        ("ACStop", ScancodeACStop),
        ("ACRefresh", ScancodeACRefresh),
        ("ACBookmarks", ScancodeACBookmarks),
        ("BrightnessDown", ScancodeBrightnessDown),
        ("BrightnessUp", ScancodeBrightnessUp),
        ("DisplaySwitch", ScancodeDisplaySwitch),
        ("KBDIllumToggle", ScancodeKBDIllumToggle),
        ("KBDIllumDown", ScancodeKBDIllumDown),
        ("KBDIllumUp", ScancodeKBDIllumUp),
        ("Eject", ScancodeEject),
        ("Sleep", ScancodeSleep),
        ("App1", ScancodeApp1),
        ("App2", ScancodeApp2)
    ]

scancodeFromString :: String -> Maybe Scancode
scancodeFromString name = lookup name keyNames

data Options = Options {
    screenScaleX :: Int,
    screenScaleY :: Int,
    topOverscan :: Int,
    bottomOverscan :: Int,
    motionBlurAlpha :: Float,

    controllerTypes :: String,

    joystick1Left :: [String],
    joystick1Right :: [String],
    joystick1Up :: [String],
    joystick1Down :: [String],
    joystick2Left :: [String],
    joystick2Right :: [String],
    joystick2Up :: [String],
    joystick2Down :: [String],
    joystick1Trigger :: [String],
    joystick2Trigger :: [String],
    dumpState :: [String],
    gameQuit :: [String],
    gameSelect :: [String],
    gameReset :: [String],
    tvType :: [String],
    enterDebugger :: [String],
    debugMode :: [String],
    writeRecord :: [String],
    delayLeft :: [String],
    delayRight :: [String],
    delayUp :: [String],
    delayDown :: [String],
    keyboardController00 :: [String],
    keyboardController01 :: [String],
    keyboardController02 :: [String],
    keyboardController03 :: [String],
    keyboardController04 :: [String],
    keyboardController05 :: [String],
    keyboardController10 :: [String],
    keyboardController11 :: [String],
    keyboardController12 :: [String],
    keyboardController13 :: [String],
    keyboardController14 :: [String],
    keyboardController15 :: [String],
    keyboardController20 :: [String],
    keyboardController21 :: [String],
    keyboardController22 :: [String],
    keyboardController23 :: [String],
    keyboardController24 :: [String],
    keyboardController25 :: [String],
    keyboardController30 :: [String],
    keyboardController31 :: [String],
    keyboardController32 :: [String],
    keyboardController33 :: [String],
    keyboardController34 :: [String],
    keyboardController35 :: [String]
} deriving (Show, Read)

defaultOptions :: Options
defaultOptions = Options {
    screenScaleX = 5,
    screenScaleY = 3,
    topOverscan = 10,
    bottomOverscan = 10,
    motionBlurAlpha = 1.0,

    controllerTypes = "Joysticks",

    joystick1Left = ["Left"],
    joystick1Right = ["Right"],
    joystick1Up = ["Up"],
    joystick1Down = ["Down"],
    joystick2Left = ["LeftBracket"],
    joystick2Right = ["RightBracket"],
    joystick2Up = ["Equals"],
    joystick2Down = ["Apostrophe"],
    joystick1Trigger = ["Space"],
    joystick2Trigger = ["Return"],
    dumpState = ["1"],
    gameQuit = ["Q"],
    gameSelect = ["C"],
    gameReset = ["V"],
    tvType = ["X"],
    enterDebugger = ["Escape"],
    debugMode = ["Backslash"],
    writeRecord = ["W"],
    delayLeft = [],
    delayRight = [],
    delayUp = [],
    delayDown = [],
    keyboardController00 = ["7"],
    keyboardController01 = ["6"],
    keyboardController02 = ["5"],
    keyboardController03 = ["0"],
    keyboardController04 = ["9"],
    keyboardController05 = ["8"],
    keyboardController10 = ["U"],
    keyboardController11 = ["Y"],
    keyboardController12 = ["T"],
    keyboardController13 = ["P"],
    keyboardController14 = ["O"],
    keyboardController15 = ["I"],
    keyboardController20 = ["J"],
    keyboardController21 = ["H"],
    keyboardController22 = ["G"],
    keyboardController23 = ["Semicolon"],
    keyboardController24 = ["L"],
    keyboardController25 = ["K"],
    keyboardController30 = ["M"],
    keyboardController31 = ["N"],
    keyboardController32 = ["B"],
    keyboardController33 = ["Slash"],
    keyboardController34 = ["Period"],
    keyboardController35 = ["Comma"]
}

data AtariKey = Joystick1Left | Joystick1Right | Joystick1Up | Joystick1Down
              | Joystick2Left | Joystick2Right | Joystick2Up | Joystick2Down
              | Joystick1Trigger |Joystick2Trigger
              | GameSelect | GameReset | TVType
              | GameQuit | DumpState | EnterDebugger | DebugMode
              | WriteRecord | DelayLeft | DelayRight | DelayUp | DelayDown
              | KeyboardController Int Int
                deriving (Eq, Show)

type AtariKeys = M.Map Scancode AtariKey

keysFromOptions :: Options -> Maybe AtariKeys
keysFromOptions options = do
    scancodes <- sequence $ map (sequence . map scancodeFromString) [
                    joystick1Left options,
                    joystick1Right options,
                    joystick1Up options,
                    joystick1Down options,
                    joystick2Left options,
                    joystick2Right options,
                    joystick2Up options,
                    joystick2Down options,
                    joystick1Trigger options,
                    joystick2Trigger options,
                    dumpState options,
                    gameQuit options,
                    gameSelect options,
                    gameReset options,
                    tvType options,
                    enterDebugger options,
                    debugMode options,
                    writeRecord options,
                    delayLeft options,
                    delayRight options,
                    delayUp options,
                    delayDown options,
                    keyboardController00 options,
                    keyboardController01 options,
                    keyboardController02 options,
                    keyboardController03 options,
                    keyboardController04 options,
                    keyboardController05 options,
                    keyboardController10 options,
                    keyboardController11 options,
                    keyboardController12 options,
                    keyboardController13 options,
                    keyboardController14 options,
                    keyboardController15 options,
                    keyboardController20 options,
                    keyboardController21 options,
                    keyboardController22 options,
                    keyboardController23 options,
                    keyboardController24 options,
                    keyboardController25 options,
                    keyboardController30 options,
                    keyboardController31 options,
                    keyboardController32 options,
                    keyboardController33 options,
                    keyboardController34 options,
                    keyboardController35 options
                ]
    let atariKeys = [
                    Joystick1Left,
                    Joystick1Right,
                    Joystick1Up,
                    Joystick1Down,
                    Joystick2Left,
                    Joystick2Right,
                    Joystick2Up,
                    Joystick2Down,
                    Joystick1Trigger,
                    Joystick2Trigger,
                    DumpState,
                    GameQuit,
                    GameSelect,
                    GameReset,
                    TVType,
                    EnterDebugger,
                    DebugMode,
                    WriteRecord,
                    DelayLeft,
                    DelayRight,
                    DelayUp,
                    DelayDown,
                    KeyboardController 0 0,
                    KeyboardController 0 1,
                    KeyboardController 0 2,
                    KeyboardController 0 3,
                    KeyboardController 0 4,
                    KeyboardController 0 5,
                    KeyboardController 1 0,
                    KeyboardController 1 1,
                    KeyboardController 1 2,
                    KeyboardController 1 3,
                    KeyboardController 1 4,
                    KeyboardController 1 5,
                    KeyboardController 2 0,
                    KeyboardController 2 1,
                    KeyboardController 2 2,
                    KeyboardController 2 3,
                    KeyboardController 2 4,
                    KeyboardController 2 5,
                    KeyboardController 3 0,
                    KeyboardController 3 1,
                    KeyboardController 3 2,
                    KeyboardController 3 3,
                    KeyboardController 3 4,
                    KeyboardController 3 5
                ]
    return $ M.fromList $ concat $ [zip scancodes (repeat deviceKeys) |
                                    (scancodes, deviceKeys) <- zip scancodes atariKeys]
