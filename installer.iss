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

[Tasks]
; Le service n'est installe/demarre que si la case est cochee ( cochee par defaut)
Name: "installservice"; Description: "Installer et demarrer le service Windows (envoi automatique des rapports)"; GroupDescription: "Options d'installation:"
Name: "autostarttray"; Description: "Demarrer automatiquement l'icone de la barre des taches a l'ouverture de Windows"; GroupDescription: "Options d'installation:"; Flags: unchecked

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Autostart tray icon for the current user (tache optionnelle)
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: autostarttray

[Run]
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "install"; Flags: runhidden; Tasks: installservice; Description: "Installer le service Windows"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "start"; Flags: runhidden; Tasks: installservice; Description: "Demarrer le service Windows"

[UninstallRun]
; Sans effet si le service n'est pas installe
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "stop"; Flags: runhidden; RunOnceId "StopSvc"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "remove"; Flags: runhidden; RunOnceId "RemoveSvc"

[UninstallDelete]
Type: files; Name: "{app}\agent_service.log"
