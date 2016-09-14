$myConfig = @{
    "SOFTWARE\ConEmu\.Vanilla" = @{
        # Main : Main console font, Alternative font -> consolas
        "FontName"                      = "Consolas"
        "FontName2"                     = "Consolas"
    
        # Main : Main console font > Anti-aliasing = "Clear Type"
        # Main : Alternative font > Anti-aliasing = true
        "Anti-aliasing"                 = 0x00000006
        "Anti-aliasing2"                = [Byte[]]@(0x01)
        
        # Main > Size & Pos : Auto save of window size and position on exit
        # -> disable
        "AutoSaveSizePos"               = [Byte[]]@(0x00)
        
        # Main > Size & Pos : Console buffer height = 5000
        "DefaultBufferHeight"           = 0x00001388
        
        # Main > Appearance : Generic > Single instance mode
        "SingleInstance"                = [Byte[]]@(0x01)
        
        # Main > Tab bar : Tab double click actions
        # -> button : duplicate tab
        # -> tab bar: open new shell
        "TabDblClick"                   = 0x00000003
        "TabBtnDblClick"                = 0x00000004
        
        # Main > Tab bar : Tabs
        # Charset = Default
        "TabFontCharSet"                = 0x00000001
        
        # Main > Confirm : Confirm actions
        # -> Confirm creating new console/tab
        "Multi.NewConfirm"              = [Byte[]]@(0x01)
        
        # Main > Task bar : Action on closing last console (tab) and 'cross
        # clicking': Quit on close, do not close with last tab
        "Multi.LeaveOnClose"            = [Byte[]]@(0x02)
        
        # Startup : Auto save/restore opened tabs
        "StartType"                     = [Byte[]]@(0x03)
        
        # Features > Status bar > Selected Columns
        # -> Active process, Active VCon, Create new console,
        #    Synchronize current dir, Num Lock state, Active console buffer,
        # Current zoom value, current DPI value, Console visible size,
        # Cursor information, System time, Size grip
        "StatusBar.Hide.ABuf"           = [Byte[]]@(0x00)
        "StatusBar.Hide.BSize"          = [Byte[]]@(0x01)
        "StatusBar.Hide.CPos"           = [Byte[]]@(0x01)
        "StatusBar.Hide.CSize"          = [Byte[]]@(0x00)
        "StatusBar.Hide.CapsL"          = [Byte[]]@(0x01)
        "StatusBar.Hide.ConEmuHWND"     = [Byte[]]@(0x01)
        "StatusBar.Hide.ConEmuPID"      = [Byte[]]@(0x01)
        "StatusBar.Hide.ConEmuView"     = [Byte[]]@(0x01)
        "StatusBar.Hide.CurI"           = [Byte[]]@(0x00)
        "StatusBar.Hide.CurS"           = [Byte[]]@(0x01)
        "StatusBar.Hide.CurX"           = [Byte[]]@(0x01)
        "StatusBar.Hide.CurY"           = [Byte[]]@(0x01)
        "StatusBar.Hide.Dpi"            = [Byte[]]@(0x00)
        "StatusBar.Hide.KeyHooks"       = [Byte[]]@(0x01)
        "StatusBar.Hide.Lang"           = [Byte[]]@(0x01)
        "StatusBar.Hide.New"            = [Byte[]]@(0x00)
        "StatusBar.Hide.NumL"           = [Byte[]]@(0x00)
        "StatusBar.Hide.Proc"           = [Byte[]]@(0x00)
        "StatusBar.Hide.RMode"          = [Byte[]]@(0x01)
        "StatusBar.Hide.Resize"         = [Byte[]]@(0x00)
        "StatusBar.Hide.ScrL"           = [Byte[]]@(0x01)
        "StatusBar.Hide.Srv"            = [Byte[]]@(0x01)
        "StatusBar.Hide.SrvHWND"        = [Byte[]]@(0x01)
        "StatusBar.Hide.Style"          = [Byte[]]@(0x01)
        "StatusBar.Hide.StyleEx"        = [Byte[]]@(0x01)
        "StatusBar.Hide.Sync"           = [Byte[]]@(0x00)
        "StatusBar.Hide.TMode"          = [Byte[]]@(0x01)
        "StatusBar.Hide.Time"           = [Byte[]]@(0x00)
        "StatusBar.Hide.Title"          = [Byte[]]@(0x01)
        "StatusBar.Hide.Transparency"   = [Byte[]]@(0x01)
        "StatusBar.Hide.VCon"           = [Byte[]]@(0x00)
        "StatusBar.Hide.VisL"           = [Byte[]]@(0x01)
        "StatusBar.Hide.WClient"        = [Byte[]]@(0x01)
        "StatusBar.Hide.WPos"           = [Byte[]]@(0x01)
        "StatusBar.Hide.WSize"          = [Byte[]]@(0x01)
        "StatusBar.Hide.WVBack"         = [Byte[]]@(0x01)
        "StatusBar.Hide.WVDC"           = [Byte[]]@(0x01)
        "StatusBar.Hide.WWork"          = [Byte[]]@(0x01)
        "StatusBar.Hide.Zoom"           = [Byte[]]@(0x00)
        "StatusBar.Hide.hFocus"         = [Byte[]]@(0x01)
        "StatusBar.Hide.hFore"          = [Byte[]]@(0x01)
        "StatusBar.Show"                = [Byte[]]@(0x01)
        
        # Features > Cpu consuming > Sleep in background
        "SleepInBackground"             = [Byte[]]@(0x01)
        
        # Features > Colors
        # PowerShell color scheme with color 09 changed to ff2828 instead
        # of default value ff0000
        "ColorTable00"                  = 0x00000000
        "ColorTable01"                  = 0x00800000
        "ColorTable02"                  = 0x00008000
        "ColorTable03"                  = 0x00808000
        "ColorTable04"                  = 0x00000080
        "ColorTable05"                  = 0x00562401
        "ColorTable06"                  = 0x00f0edee
        "ColorTable07"                  = 0x00c0c0c0
        "ColorTable08"                  = 0x00808080
        "ColorTable09"                  = 0x00ff2828
        "ColorTable10"                  = 0x0000ff00
        "ColorTable11"                  = 0x00ffff00
        "ColorTable12"                  = 0x000000ff
        "ColorTable13"                  = 0x00ff00ff
        "ColorTable14"                  = 0x0000ffff
        "ColorTable15"                  = 0x00ffffff
        "ColorTable16"                  = 0x00000000
        "ColorTable17"                  = 0x00800000
        "ColorTable18"                  = 0x00008000
        "ColorTable19"                  = 0x00808000
        "ColorTable20"                  = 0x00000080
        "ColorTable21"                  = 0x00800080
        "ColorTable22"                  = 0x00008080
        "ColorTable23"                  = 0x00c0c0c0
        "ColorTable24"                  = 0x00808080
        "ColorTable25"                  = 0x00ff0000
        "ColorTable26"                  = 0x0000ff00
        "ColorTable27"                  = 0x00ffff00
        "ColorTable28"                  = 0x000000ff
        "ColorTable29"                  = 0x00ff00ff
        "ColorTable30"                  = 0x0000ffff
        "ColorTable31"                  = 0x00ffffff
        "ExtendColors"                  = [Byte[]]@(0x00)
        "ExtendColorIdx"                = [Byte[]]@(0x0e)
        "TextColorIdx"                  = [Byte[]]@(0x06)
        "BackColorIdx"                  = [Byte[]]@(0x05)
        "PopTextColorIdx"               = [Byte[]]@(0x03)
        "PopBackColorIdx"               = [Byte[]]@(0x0f)
        
        # Features > Transparency - Different transparency when (in)active
        "AlphaValue"                    = [Byte[]]@(0xe6) # ~90% opacity when active
        "AlphaValueSeparate"            = [Byte[]]@(0x01) # other opacity when inactive
        "AlphaValueInactive"            = [Byte[]]@(0xa6) # ~65% opacity when inactive
        
        # Integration > ComSpec : Cmd.exe output codepage = Unicode (/U)
        "CmdOutputCP"                   = 0x00000002
        
        # Keys & Macro > Mark/Copy : Freeze console contents before selection
        "CTS.Freeze"                    = [Byte[]]@(0x01)
        
        
        # Default values as of ConEmu 16.09.04
        "16bit Height"                  = 0x00000000
        "ActivateSplitMouseOver"        = [Byte[]]@(0x01)
        "AdminShowShield"               = [Byte[]]@(0x01)
        "AdminTitleSuffix"              = " (Admin)"
        "AffinityMask"                  = 0x00000000
        "AlwaysOnTop"                   = [Byte[]]@(0x00)
        "AlwaysShowTrayIcon"            = [Byte[]]@(0x00)
        "AnsiAllowedCommands"           = [String[]]@("cmd -cur_console:R /cGitShowBranch.cmd")
        "AnsiExecution"                 = [Byte[]]@(0x01)
        "AnsiLog"                       = [Byte[]]@(0x00)
        "AnsiLogPath"                   = "%ConEmuDir%\Logs\"
        "AutoBufferHeight"              = [Byte[]]@(0x01)
        "BackGround Image"              = "c:\back.bmp"
        "BackGround Image show"         = [Byte[]]@(0x00)
        "bgImageColors"                 = 0xffffffff
        "bgImageDarker"                 = [Byte[]]@(0xff)
        "bgOperation"                   = [Byte[]]@(0x00)
        "bgPluginAllowed"               = [Byte[]]@(0x01)
        "Cascaded"                      = [Byte[]]@(0x01)
        "CenterConsolePad"              = 0x00000000
        "ClipboardAllLines"             = [Byte[]]@(0x01)
        "ClipboardArrowStart"           = [Byte[]]@(0x01)
        "ClipboardBashMargin"           = [Byte[]]@(0x00)
        "ClipboardClickPromptPosition"  = [Byte[]]@(0x02)
        "ClipboardConfirmEnter"         = [Byte[]]@(0x01)
        "ClipboardConfirmLonger"        = 0x000000c8
        "ClipboardDeleteLeftWord"       = [Byte[]]@(0x02)
        "ClipboardDetectLineEnd"        = [Byte[]]@(0x01)
        "ClipboardEOL"                  = [Byte[]]@(0x00)
        "ClipboardFirstLine"            = [Byte[]]@(0x01)
        "ClipboardTrimTrailing"         = [Byte[]]@(0x02)
        "CmdLine"                       = ""
        "ColorKeyTransparent"           = [Byte[]]@(0x00)
        "ColorKeyValue"                 = 0x00010101
        "CompressLongStrings"           = [Byte[]]@(0x01)
        "ComSpec.Bits"                  = [Byte[]]@(0x00)
        "ComSpec.EnvAddExePath"         = [Byte[]]@(0x01)
        "ComSpec.EnvAddPath"            = [Byte[]]@(0x01)
        "ComSpec.Path"                  = ""
        "ComSpec.Type"                  = [Byte[]]@(0x00)
        "ComSpec.UncPaths"              = [Byte[]]@(0x00)
        "ComSpec.UpdateEnv"             = [Byte[]]@(0x00)
        "ConsoleExceptionHandler"       = [Byte[]]@(0x00)
        "ConsoleFontHeight"             = 0x00000005
        "ConsoleFontName"               = "Lucida Console"
        "ConsoleFontWidth"              = 0x00000003
        "ConVisible"                    = [Byte[]]@(0x00)
        "ConWnd Height"                 = 0x00000028
        "ConWnd Width"                  = 0x00000078
        "ConWnd X"                      = 0xfffffa1a
        "ConWnd Y"                      = 0x00000104
        "CTS.AutoCopy"                  = [Byte[]]@(0x01)
        "CTS.ColorIndex"                = [Byte[]]@(0xe0)
        "CTS.EndOnKeyPress"             = [Byte[]]@(0x00)
        "CTS.EndOnTyping"               = [Byte[]]@(0x00)
        "CTS.EraseBeforeReset"          = [Byte[]]@(0x01)
        "CTS.ForceLocale"               = 0x00000000
        "CTS.HtmlFormat"                = [Byte[]]@(0x00)
        "CTS.IBeam"                     = [Byte[]]@(0x01)
        "CTS.Intelligent"               = [Byte[]]@(0x01)
        "CTS.IntelligentExceptions"     = "far|vim"
        "CTS.MBtnAction"                = [Byte[]]@(0x00)
        "CTS.RBtnAction"                = [Byte[]]@(0x03)
        "CTS.ResetOnRelease"            = [Byte[]]@(0x00)
        "CTS.SelectBlock"               = [Byte[]]@(0x01)
        "CTS.SelectText"                = [Byte[]]@(0x01)
        "CursorTypeActive"              = 0x000232c1
        "CursorTypeInactive"            = 0x00823283
        "DebugLog"                      = [Byte[]]@(0x00)
        "DebugSteps"                    = [Byte[]]@(0x00)
        "DefaultTerminalAgressive"      = [Byte[]]@(0x01)
        "DefaultTerminalApps"           = "explorer.exe"
        "DefaultTerminalConfirm"        = [Byte[]]@(0x01)
        "DefaultTerminalDebugLog"       = [Byte[]]@(0x00)
        "DefaultTerminalNewWindow"      = [Byte[]]@(0x00)
        "DefaultTerminalNoInjects"      = [Byte[]]@(0x00)
        "DefCopy"                       = [Byte[]]@(0x01)
        "DisableAllFlashing"            = [Byte[]]@(0x00)
        "DisableFarFlashing"            = [Byte[]]@(0x00)
        "DisableMouse"                  = [Byte[]]@(0x00)
        "Dnd"                           = [Byte[]]@(0x01)
        "DndDrop"                       = [Byte[]]@(0x01)
        "DownShowExOnTopMessage"        = [Byte[]]@(0x00)
        "DownShowHiddenMessage"         = [Byte[]]@(0x00)
        "DragOverlay"                   = [Byte[]]@(0x01)
        "DragPanel"                     = [Byte[]]@(0x02)
        "DragPanelBothEdges"            = [Byte[]]@(0x00)
        "DragShowIcons"                 = [Byte[]]@(0x01)
        "DropUseMenu"                   = [Byte[]]@(0x02)
        "EnhanceButtons"                = [Byte[]]@(0x00)
        "EnhanceGraphics"               = [Byte[]]@(0x01)
        "EnvironmentSet"                = [String[]]@("set PATH=%ConEmuBaseDir%\Scripts;%PATH%")
        "ExtendFontBoldIdx"             = [Byte[]]@(0x0c)
        "ExtendFontItalicIdx"           = [Byte[]]@(0x0d)
        "ExtendFontNormalIdx"           = [Byte[]]@(0x01)
        "ExtendFonts"                   = [Byte[]]@(0x00)
        "ExtendUCharMap"                = [Byte[]]@(0x01)
        "FadeInactive"                  = [Byte[]]@(0x01)
        "FadeInactiveHigh"              = [Byte[]]@(0xd0)
        "FadeInactiveLow"               = [Byte[]]@(0x00)
        "FarGotoEditorOpt"              = [Byte[]]@(0x01)
        "FarGotoEditorPath"             = "far.exe /e%1:%2 ""%3"""
        "FarHourglass"                  = [Byte[]]@(0x01)
        "FarHourglassDelay"             = 0x000001f4
        "FARuseASCIIsort"               = [Byte[]]@(0x00)
        "FindMatchCase"                 = [Byte[]]@(0x00)
        "FindMatchWholeWords"           = [Byte[]]@(0x00)
        "FindText"                      = ""
        "FindTransparent"               = [Byte[]]@(0x01)
        "FixAltOnAltTab"                = [Byte[]]@(0x00)
        "FixFarBorders"                 = [Byte[]]@(0x01)
        "FixFarBordersRanges"           = "2013-25C4;"
        "FocusInChildWindows"           = [Byte[]]@(0x01)
        "FontAutoSize"                  = [Byte[]]@(0x00)
        "FontBold"                      = [Byte[]]@(0x00)
        "FontCharSet"                   = [Byte[]]@(0x01)
        "FontItalic"                    = [Byte[]]@(0x00)
        "FontSize"                      = 0x0000000e
        "FontSizeX"                     = 0x00000000
        "FontSizeX2"                    = 0x00000000
        "FontSizeX3"                    = 0x00000000
        "FontUseDpi"                    = [Byte[]]@(0x01)
        "FontUseUnits"                  = [Byte[]]@(0x01)
        "HideCaption"                   = [Byte[]]@(0x00)
        "HideCaptionAlways"             = [Byte[]]@(0x00)
        "HideCaptionAlwaysDelay"        = 0x000007d0
        "HideCaptionAlwaysDisappear"    = 0x000007d0
        "HideCaptionAlwaysFrame"        = [Byte[]]@(0xff)
        "HideChildCaption"              = [Byte[]]@(0x01)
        "HideInactiveConsoleTabs"       = [Byte[]]@(0x00)
        "HighlightMouseCol"             = [Byte[]]@(0x00)
        "HighlightMouseRow"             = [Byte[]]@(0x00)
        "IconID"                        = 0x00000001
        "IntegralSize"                  = [Byte[]]@(0x00)
        "JumpListAutoUpdate"            = [Byte[]]@(0x01)
        "KeyBarRClick"                  = [Byte[]]@(0x01)
        "KeyboardHooks"                 = [Byte[]]@(0x01)
        "LastMonitor"                   = "-1920,142,0,1312"
        "MainTimerElapse"               = 0x0000000a
        "MainTimerInactiveElapse"       = 0x000003e8
        "MapShiftEscToEsc"              = [Byte[]]@(0x01)
        "Min2Tray"                      = [Byte[]]@(0x00)
        "MinimizeOnLoseFocus"           = [Byte[]]@(0x00)
        "MonitorConsoleLang"            = [Byte[]]@(0x03)
        "Monospace"                     = [Byte[]]@(0x01)
        "MouseDragWindow"               = [Byte[]]@(0x01)
        "MouseSkipActivation"           = [Byte[]]@(0x01)
        "MouseSkipMoving"               = [Byte[]]@(0x01)
        "Multi"                         = [Byte[]]@(0x01)
        "Multi.AutoCreate"              = [Byte[]]@(0x00)
        "Multi.CloseConfirmFlags"       = [Byte[]]@(0x04)
        "Multi.DetachConfirm"           = [Byte[]]@(0x01)
        "Multi.DupConfirm"              = [Byte[]]@(0x01)
        "Multi.HideOnClose"             = [Byte[]]@(0x00)
        "Multi.Iterate"                 = [Byte[]]@(0x01)
        "Multi.MinByEsc"                = [Byte[]]@(0x02)
        "Multi.NumberInCaption"         = [Byte[]]@(0x00)
        "Multi.ShowButtons"             = [Byte[]]@(0x01)
        "Multi.ShowSearch"              = [Byte[]]@(0x01)
        "Multi.SplitHeight"             = [Byte[]]@(0x04)
        "Multi.SplitWidth"              = [Byte[]]@(0x04)
        "Multi.UseArrows"               = [Byte[]]@(0x00)
        "Multi.UseNumbers"              = [Byte[]]@(0x01)
        "Multi.UseWinTab"               = [Byte[]]@(0x00)
        "OneTabPerGroup"                = [Byte[]]@(0x00)
        "PanView.BackColor"             = 0x30ffffff
        "PanView.LoadFolders"           = [Byte[]]@(0x01)
        "PanView.LoadPreviews"          = [Byte[]]@(0x03)
        "PanView.LoadTimeout"           = 0x0000000f
        "PanView.MaxZoom"               = 0x00000258
        "PanView.PFrame"                = 0x00000001
        "PanView.PFrameColor"           = 0x28808080
        "PanView.RestoreOnStartup"      = [Byte[]]@(0x00)
        "PanView.SFrame"                = 0x00000001
        "PanView.SFrameColor"           = 0x07c0c0c0
        "PanView.Thumbs.FontHeight"     = 0x0000000e
        "PanView.Thumbs.FontName"       = "Segoe UI"
        "PanView.Thumbs.ImgSize"        = 0x00000060
        "PanView.Thumbs.LabelPadding"   = 0x00000000
        "PanView.Thumbs.LabelSpacing"   = 0x00000002
        "PanView.Thumbs.SpaceX1"        = 0x00000001
        "PanView.Thumbs.SpaceX2"        = 0x00000005
        "PanView.Thumbs.SpaceY1"        = 0x00000001
        "PanView.Thumbs.SpaceY2"        = 0x00000014
        "PanView.Tiles.FontHeight"      = 0x0000000e
        "PanView.Tiles.FontName"        = "Segoe UI"
        "PanView.Tiles.ImgSize"         = 0x00000030
        "PanView.Tiles.LabelPadding"    = 0x00000001
        "PanView.Tiles.LabelSpacing"    = 0x00000004
        "PanView.Tiles.SpaceX1"         = 0x00000004
        "PanView.Tiles.SpaceX2"         = 0x000000ac
        "PanView.Tiles.SpaceY1"         = 0x00000004
        "PanView.Tiles.SpaceY2"         = 0x00000004
        "PanView.UsePicView2"           = [Byte[]]@(0x01)
        "PartBrush25"                   = [Byte[]]@(0x5a)
        "PartBrush50"                   = [Byte[]]@(0x96)
        "PartBrush75"                   = [Byte[]]@(0xc8)
        "PartBrushBlack"                = [Byte[]]@(0x20)
        "ProcessAnsi"                   = [Byte[]]@(0x01)
        "ProcessCmdStart"               = [Byte[]]@(0x00)
        "ProcessCtrlZ"                  = [Byte[]]@(0x00)
        "ProcessNewConArg"              = [Byte[]]@(0x01)
        "QuakeAnimation"                = 0x0000012c
        "QuakeStyle"                    = [Byte[]]@(0x00)
        "Restore2ActiveMon"             = [Byte[]]@(0x00)
        "RetardInactivePanes"           = [Byte[]]@(0x00)
        "RightClick opens context menu" = [Byte[]]@(0x02)
        "RightClickMacro2"              = ""
        "RSelectionFix"                 = [Byte[]]@(0x01)
        "SafeFarClose"                  = [Byte[]]@(0x01)
        "SafeFarCloseMacro"             = ""
        "SaveAllEditors"                = ""
        "SaveCmdHistory"                = [Byte[]]@(0x01)
        "ScrollBarAppearDelay"          = 0x00000064
        "ScrollBarDisappearDelay"       = 0x000003e8
        "SendAltEsc"                    = [Byte[]]@(0x00)
        "SendAltPrintScrn"              = [Byte[]]@(0x00)
        "SendAltTab"                    = [Byte[]]@(0x00)
        "SendCtrlEsc"                   = [Byte[]]@(0x00)
        "SendPrintScrn"                 = [Byte[]]@(0x00)
        "SetDefaultTerminal"            = [Byte[]]@(0x00)
        "SetDefaultTerminalStartup"     = [Byte[]]@(0x00)
        "SetDefaultTerminalStartupTSA"  = [Byte[]]@(0x00)
        "ShellNoZoneCheck"              = [Byte[]]@(0x00)
        "ShowFarWindows"                = [Byte[]]@(0x01)
        "ShowHelpTooltips"              = [Byte[]]@(0x01)
        "ShowScrollbar"                 = [Byte[]]@(0x02)
        "SkipFocusEvents"               = [Byte[]]@(0x00)
        "SnapToDesktopEdges"            = [Byte[]]@(0x00)
        "StartCreateDelay"              = 0x00000064
        "StartFarEditors"               = [Byte[]]@(0x00)
        "StartFarFolders"               = [Byte[]]@(0x00)
        "StartTasksFile"                = ""
        "StartTasksName"                = "{Shells::cmd}"
        "StatusBar.Color.Back"          = 0x00423607
        "StatusBar.Color.Dark"          = 0x00a1a193
        "StatusBar.Color.Light"         = 0x00e3f6fd
        "StatusBar.Flags"               = 0x00000002
        "StatusFontCharSet"             = 0x00000000
        "StatusFontFace"                = "Segoe UI"
        "StatusFontHeight"              = 0x0000000c
        "StoreTaskbarCommands"          = [Byte[]]@(0x00)
        "StoreTaskbarkTasks"            = [Byte[]]@(0x01)
        "SuppressBells"                 = [Byte[]]@(0x01)
        "TabCloseMacro"                 = ""
        "TabConsole"                    = "<%c> %s"
        "TabEditor"                     = "<%c.%i>{%s}"
        "TabEditorModified"             = "<%c.%i>[%s] *"
        "TabFlashChanged"               = 0x00000008
        "TabFontFace"                   = "Segoe UI"
        "TabFontHeight"                 = 0x0000000d
        "TabIcons"                      = [Byte[]]@(0x01)
        "TabLazy"                       = [Byte[]]@(0x01)
        "TabLenMax"                     = 0x00000014
        "TabModifiedSuffix"             = "[*]"
        "TabPanels"                     = "<%c> %s"
        "TabRecent"                     = [Byte[]]@(0x01)
        "Tabs"                          = [Byte[]]@(0x01)
        "TabSelf"                       = [Byte[]]@(0x01)
        "TabSkipWords"                  = "Administrator:|Администратор:"
        "TabsLocation"                  = [Byte[]]@(0x00)
        "TabsOnTaskBar"                 = [Byte[]]@(0x02)
        "TabViewer"                     = "<%c.%i>[%s]"
        "TaskBarOverlay"                = [Byte[]]@(0x01)
        "TaskbarProgress"               = [Byte[]]@(0x01)
        "ToolbarAddSpace"               = 0x00000000
        "TrueColorerSupport"            = [Byte[]]@(0x01)
        "TryToCenter"                   = [Byte[]]@(0x00)
        "Update.ArcCmdLine"             = ""
        "Update.CheckHourly"            = [Byte[]]@(0x00)
        "Update.CheckOnStartup"         = [Byte[]]@(0x00)
        "Update.ConfirmDownload"        = [Byte[]]@(0x01)
        "Update.DownloadPath"           = "%TEMP%\ConEmu"
        "Update.ExeCmdLine"             = ""
        "Update.InetTool"               = [Byte[]]@(0x00)
        "Update.InetToolCmd"            = ""
        "Update.LeavePackages"          = [Byte[]]@(0x00)
        "Update.PostUpdateCmd"          = "echo Last successful update>ConEmuUpdate.info && date /t>>ConEmuUpdate.info && time /t>>ConEmuUpdate.info"
        "Update.Proxy"                  = ""
        "Update.ProxyPassword"          = ""
        "Update.ProxyUser"              = ""
        "Update.UseBuilds"              = [Byte[]]@(0x02)
        "Update.UseProxy"               = [Byte[]]@(0x00)
        "Update.VerLocation"            = ""
        "UseAltGrayPlus"                = [Byte[]]@(0x01)
        "UseClink"                      = [Byte[]]@(0x01)
        "UseCurrentSizePos"             = [Byte[]]@(0x01)
        "UseInjects"                    = [Byte[]]@(0x01)
        "UserScreenTransparent"         = [Byte[]]@(0x00)
        "UseScrollLock"                 = [Byte[]]@(0x01)
        "VividColors"                   = [Byte[]]@(0x01)
        "WindowMode"                    = 0x0000051f
    }
}
Install-UserProfileRegistryImage -Image $myConfig -Force