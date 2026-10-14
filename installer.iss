; Inno Setup script for the Dolibarr Sysinfo Agent.
; Prerequisite: run build_exe.bat first so that dist\DolibarrAgent.exe
; and dist\DolibarrAgentTray.exe exist.
;
; Build the installer with:
;   ISCC.exe installer.iss
; Resulting installer: Output\DolibarrSysinfoAgentSetup.exe

#define MyAppName "Dolibarr Sysinfo Agent"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "BB2A"
#define MyAppExeName "DolibarrAgentTray.exe"
#define MyAppServiceExeName "DolibarrAgent.exe"

[Setup]
AppId={{7E3A1B5C-9D4F-4E8A-B2C6-1F5D8A9E0B31}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\DolibarrSysinfoAgent
DefaultGroupName={#MyAppName}
OutputBaseFilename=DolibarrSysinfoAgentSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
UninstallDisplayName={#MyAppName}

[Files]
Source: "dist\{#MyAppServiceExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.example.json"; DestDir: "{app}"; DestName: "config.json"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Autostart tray icon for the current user (systematique)
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"

[Run]
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "install"; Flags: runhidden; Description: "Installer le service Windows"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "start"; Flags: runhidden; Description: "Demarrer le service Windows"

[UninstallRun]
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "stop"; Flags: runhidden; RunOnceId "StopSvc"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "remove"; Flags: runhidden; RunOnceId "RemoveSvc"

[UninstallDelete]
Type: files; Name: "{app}\agent_service.log"
