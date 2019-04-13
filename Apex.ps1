# Script Vars
## Apex Launch Options
$ApexLauchOptions = '-novid -refresh 60 +exec autoexec -preload +fps_max unlimited -threads 4 -forcenovsync -high -window -noborder'
## Desktop Resolution and Hrz
$DesktopHrz = 60
$DesktopWidth = 1920
$DesktopHeight = 1080
## Apex Resolution and Hrz
$ApexHrz = 60
$ApexScreenWidth = 1280
$ApexScreenHeight = 720


#Set Window Locations For Streaming
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}
$ScriptPWD = Get-ScriptDirectory

# .Net Hide Console
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
Function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}

# Set Screen Resolution
Function Set-ScreenResolution { 
param ( 
[Parameter(Mandatory=$true, 
           Position = 0)] 
[int] 
$Width, 
 
[Parameter(Mandatory=$true, 
           Position = 1)] 
[int] 
$Height, 

[Parameter(Mandatory=$true, 
           Position = 2)] 
[int] 
$Freq
) 
 
$pinvokeCode = @" 
 
using System; 
using System.Runtime.InteropServices; 
 
namespace Resolution 
{ 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 
 
        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 
 
        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 
 
        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 
 
        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 
 
        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 
 
 
 
    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 
 
        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 
 
 
 
    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution(int width, int height, int freq) 
        { 
 
            DEVMODE1 dm = GetDevMode1(); 
 
            if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
            { 
 
                dm.dmPelsWidth = width; 
                dm.dmPelsHeight = height; 
                dm.dmDisplayFrequency = freq;
 
                int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 
 
                if (iRet == User_32.DISP_CHANGE_FAILED) 
                { 
                    return "Unable to process your request. Sorry for this inconvenience."; 
                } 
                else 
                { 
                    iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case User_32.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "Success"; 
                            } 
                        case User_32.DISP_CHANGE_RESTART: 
                            { 
                                return "You need to reboot for the change to happen.\n If you feel any problems after rebooting your machine\nThen try to change resolution in Safe Mode."; 
                            } 
                        default: 
                            { 
                                return "Failed to change the resolution"; 
                            } 
                    } 
 
                } 
 
 
            } 
            else 
            { 
                return "Failed to change the resolution."; 
            } 
        } 
 
        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 
 
"@ 
 
Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution($width,$height,$freq) 
} 

# Build/Backup/Set Apex Config Files
Function Set-ApexConfig {
	$Localautoexec = Test-Path -Path ./autoexec.cfg
	$Remoteautoexec = Test-Path -Path ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\autoexec.cfg'
	If ( $Localautoexec -eq 'True' ) {
		Write-Host 'Copying autoexec.cfg'
		Copy-Item  .\autoexec.cfg -Destination ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\' -Recurse -Force
		Copy-Item  .\vidsettings.cfg -Destination ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\' -Recurse -Force
	}
	Else {
		If ( $Remoteautoexec  -eq 'True' ) {
			Write-Host 'Backing Up autoexec.cfg'
			Copy-Item  ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\autoexec.cfg' -Destination .\ -Recurse -Force
		}
		Else {
			Write-Host 'Creating autoexec.cfg'
			New-Item -ItemType file ./autoexec.cfg
			Copy-Item  .\autoexec.cfg -Destination ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\' -Recurse -Force
			Copy-Item  .\vidsettings.cfg -Destination ${env:ProgramFiles(x86)}'\Origin Games\Apex\cfg\' -Recurse -Force
		}
	}
	$LocalApex = Test-Path -Path ./Apex
	$RemoteApex = Test-Path -Path $env:USERPROFILE'\Saved Games\Respawn\Apex'
	If ( $LocalApex -eq 'True' ) {
		Write-Host 'Copying ./Apex Folder'
		Copy-Item  .\Apex -Destination $env:USERPROFILE'\Saved Games\Respawn\' -Recurse -Force
	}
	Else {
		If ( $RemoteApex -eq 'True' ) {
			Write-Host 'Backing Up ./Apex Folder'
			Copy-Item  $env:USERPROFILE'\Saved Games\Respawn\Apex' -Destination .\ -Recurse -Force
		}
	}
}

# Change Cursor
$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser", "$env:COMPUTERNAME")
$RegCursors = $RegConnect.OpenSubKey("Control Panel\Cursors", $true)
$RegCursors.SetValue("Arrow", $ScriptPWD+"\crosshair.cur")
$RegCursors.Close()
$RegConnect.Close()
$CSharpSig = @'
[DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool SystemParametersInfo(
                 uint uiAction,
                 uint uiParam,
                 bool pvParam,
                 uint fWinIni);
'@

$CursorRefresh = Add-Type -MemberDefinition $CSharpSig -Name WinAPICall -Namespace SystemParamInfo -Passthru
$CursorRefresh::SystemParametersInfo(0x0057, 0, $null, 0)

# Fix for Spinning Wheel (Deletes a Temp File of previusgamestate.txt Forcing Apex to autodetect the Data Center everytime)
$ApexBadFile = Test-Path -Path $env:USERPROFILE'\Saved Games\Respawn\Apex\local\previousgamestate.txt'
If ( $ApexBadFile -eq 'True' ) {
	Remove-Item -Path $env:USERPROFILE'\Saved Games\Respawn\Apex\local\previousgamestate.txt'
}

# Main Script To Start Apex
Set-ApexConfig
Hide-Console
Set-ScreenResolution -Width $ApexScreenWidth -Height $ApexScreenHeight -freq $ApexHrz
Start-Process -FilePath ${env:ProgramFiles(x86)}'\Origin Games\Apex\r5apex.exe' -ArgumentList $ApexLauchOptions -Wait 
Set-ScreenResolution -Width $DesktopWidth -Height $DesktopHeight -freq $DesktopHrz

# Reset Cursor
$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser", "$env:COMPUTERNAME")
$RegCursors = $RegConnect.OpenSubKey("Control Panel\Cursors", $true)
$RegCursors.SetValue("Arrow", "%SystemRoot%\cursors\aero_arrow.cur")
$RegCursors.Close()
$RegConnect.Close()
$CursorRefresh::SystemParametersInfo(0x0057, 0, $null, 0)