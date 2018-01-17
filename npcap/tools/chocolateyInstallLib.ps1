function Compile-PInvoke() {
    $code = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

namespace Native {   
    // https://msdn.microsoft.com/en-us/library/windows/desktop/ff468861(v=vs.85).aspx
    public enum SystemDefinedMessage : uint {
        WM_NEXTDLGCTL = 0x028,
        WM_KEYDOWN    = 0x100,
        WM_KEYUP      = 0x101,
        WM_CHAR       = 0x102,
        WM_COMMAND    = 0x0111,
        BM_CLICK      = 0x0f5
    }

    public static class NativeMethods {   
        private static StringBuilder buffer = new StringBuilder(10);
    
        public static bool IsEnabledButton(IntPtr hWnd) {
            GetClassName(hWnd, buffer, buffer.Capacity);
            return buffer.ToString().ToLowerInvariant() == "button"
                && IsWindowEnabled(hWnd);
        }
        
        public static string GetWindowText(IntPtr hWnd) {
            GetWindowText(hWnd, buffer, buffer.Capacity);
            return buffer.ToString();
        }
        
        public static IList<IntPtr> EnumChildWindows(IntPtr hwndParent) {
            var result = new List<IntPtr>();
            EnumChildWindows(
                hwndParent,
                (hwnd, param) => {
                    result.Add(hwnd); return true; 
                },
                IntPtr.Zero);
            return result;
        }
        
        
        [DllImport("User32.Dll", EntryPoint = "PostMessageA")]
        public static extern bool PostMessage(IntPtr hWnd, uint msg, int wParam, int lParam);
        
        [DllImport("user32.dll")]
        public static extern int GetDlgCtrlID(IntPtr hwndCtl);
        
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName,int nMaxCount);
        
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool IsWindowEnabled(IntPtr hWnd);
        
        private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);
        
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool EnumChildWindows(IntPtr hwndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);
    }
}
"@

    # Set up the compiler params, including any references required for the compilation
    $codeProvider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $dependencies = @()
    $compilerParams = New-Object System.CodeDom.Compiler.CompilerParameters(,$dependencies)

    $compilationResult = $codeProvider.CompileAssemblyFromSource($compilerParams, $code);

    # Force loading the generated assembly by accessing it
    $assembly = $compilationResult.CompiledAssembly
    $compilationResult.Errors | out-host
}


function Click-Button($proc, $textPatterns) {
    $mainHwnd = [IntPtr]$proc.MainWindowHandle
    $allHwnds = [Native.NativeMethods]::EnumChildWindows($mainHwnd)
    $textPatternList = @() + $textPatterns
    
    foreach ($hwnd in $allHwnds) {
        if (-not [Native.NativeMethods]::IsEnabledButton($hwnd)) {
            continue;
        }
        
        $text = [Native.NativeMethods]::GetWindowText($hwnd)
        if ([String]::IsNullOrEmpty($text)) {
            continue;
        }
        
        foreach ($pattern in $textPatternList) {
            if ($text -like $pattern) {
                
                # code 0 works well
                $notificationCode = 0
                $ctrlId = [Native.NativeMethods]::GetDlgCtrlID($hwnd)
                
                $wParam = ($notificationCode -shl 16) -bor $ctrlId
                $lParam = $hwnd.ToInt32()
                return [Native.NativeMethods]::PostMessage(
                    [IntPtr]$mainHwnd,
                    [Native.SystemDefinedMessage]::WM_COMMAND,
                    $wParam, $lParam)
            }
        }
    }
    
    return $false
}

function Get-IsNoTimeout($tStart, $timeoutSec) {
    return $($(Get-Date) - $tStart).TotalSeconds -le $timeoutSec
}


Compile-PInvoke
$exeInstaller = Get-Item "$toolsDir/npcap-*.exe"
