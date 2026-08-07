# alt_ptt.ps1 — Alt key Push-to-Talk untuk Wispr Flow
# Hold Alt = mic ON, Release Alt = mic OFF
# Runs as background process

param(
    [switch]$Stop
)

$scriptPath = Join-Path $PSScriptRoot "alt_ptt.cs"
$exePath = Join-Path $PSScriptRoot "alt_ptt.exe"

if ($Stop) {
    Get-Process -Name "alt_ptt" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "Alt PTT stopped."
    exit 0
}

# C# source for global keyboard hook + PTT simulation
$csSource = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

class AltPTT {
    [DllImport("user32.dll")]
    static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc callback, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")]
    static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")]
    static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetModuleHandle(string lpModuleName);

    delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    static LowLevelKeyboardProc _proc = HookCallback;
    static IntPtr _hookID = IntPtr.Zero;
    static bool altHeld = false;

    const int WH_KEYBOARD_LL = 13;
    const int WM_KEYDOWN = 0x0100;
    const int WM_KEYUP = 0x0101;
    const int WM_SYSKEYDOWN = 0x0104;
    const int WM_SYSKEYUP = 0x0105;
    const int VK_MENU = 0x12;
    const int VK_LMENU = 0xA4;
    const int VK_RMENU = 0xA5;

    // F14 — commonly used for PTT, same as DPI button scancode
    const int PTT_KEY = 0x7D; // VK_F14
    const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    const uint KEYEVENTF_KEYUP = 0x0002;

    [DllImport("user32.dll")]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    static void SendPTT(bool down) {
        keybd_event((byte)PTT_KEY, 0x41, down ? KEYEVENTF_EXTENDEDKEY : (uint)(KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP), UIntPtr.Zero);
    }

    static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0) {
            int vkCode = Marshal.ReadInt32(lParam);

            if (vkCode == VK_MENU || vkCode == VK_LMENU || vkCode == VK_RMENU) {
                int msg = (int)wParam;
                if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
                    if (!altHeld) {
                        altHeld = true;
                        SendPTT(true);
                    }
                    return (IntPtr)1; // Block Alt from reaching apps
                } else if (msg == WM_KEYUP || msg == WM_SYSKEYUP) {
                    if (altHeld) {
                        altHeld = false;
                        SendPTT(false);
                    }
                    return (IntPtr)1; // Block Alt release
                }
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    [STAThread]
    static void Main() {
        _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(null), 0);
        Console.WriteLine("Alt PTT active. Hold ALT to talk, release to stop.");
        Console.WriteLine("Press Ctrl+C to exit.");
        Application.Run();
        UnhookWindowsHookEx(_hookID);
    }
}
'@

# Write C# source
Set-Content -Path $scriptPath -Value $csSource -Encoding UTF8

# Compile
$csc = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

& $csc /target:exe /out:$exePath /reference:System.Windows.Forms.dll /reference:System.dll $scriptPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed"
    exit 1
}

Remove-Item $scriptPath -Force

# Start background process
$proc = Start-Process -FilePath $exePath -NoNewWindow -PassThru
Write-Host "Alt PTT started (PID: $($proc.Id)). Hold ALT to talk, release to stop."
Write-Host "Run 'alt_ptt.ps1 -Stop' to quit."
