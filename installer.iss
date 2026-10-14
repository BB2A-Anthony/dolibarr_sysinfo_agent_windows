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

[Types]
Name: "full"; Description: "Installation complete"

[Components]
Name: "main"; Description: "{#MyAppName}"; Types: full; Flags: fixed

[Files]
Source: "dist\{#MyAppServiceExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.example.json"; DestDir: "{app}"; DestName: "config.json"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Autostart tray icon for the current user (systematique)
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"

[Code]
var
  EnrollPage: TInputQueryWizardPage;
  EnrollResult: Integer;

procedure InitializeWizard;
begin
  EnrollPage := CreateInputQueryPage(wpSelectDir,
    'Enrolement Dolibarr',
    'Rattachez cette machine a un tiers Dolibarr',
    'Le code est genere sur la fiche du tiers (bouton Ajouter une machine), valable 5 minutes, a usage unique. Si vous n''etes pas pret, laissez vide: vous pourrez enroller plus tard via l''icone de la barre des taches.');
  EnrollPage.Add('URL Dolibarr:', False);
  EnrollPage.Add('Code d''enrolement:', False);
  EnrollPage.Values[0] := '';
  EnrollPage.Values[1] := '';
end;

function EnrollNow: Boolean;
var
  Url, Code, BaseCmd: string;
  ResultCode: Integer;
begin
  Result := False;
  Url := Trim(EnrollPage.Values[0]);
  Code := Trim(EnrollPage.Values[1]);
  if (Url = '') or (Code = '') then
    exit;
  BaseCmd := '--enroll-url "' + Url + '" --enroll-code "' + Code + '"';
  try
    Exec(ExpandConstant('{app}') + '\\' + '{#MyAppExeName}',
      BaseCmd,
      ExpandConstant('{app}'), SW_SHOW, ewWaitUntilTerminated, ResultCode);
    if ResultCode = 1 then begin
      if MsgBox(
        'Cette machine est deja rattachee a un autre tiers Dolibarr.' + #13#10 +
        'Confirmer la reaffectation de cette machine ?',
        mbConfirmation, MB_YESNO) = IDYES then
      begin
        Exec(ExpandConstant('{app}') + '\\' + '{#MyAppExeName}',
          BaseCmd + ' --confirm-reassign',
          ExpandConstant('{app}'), SW_SHOW, ewWaitUntilTerminated, ResultCode);
      end;
    end;
    EnrollResult := ResultCode;
    Result := (ResultCode = 0);
  except
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Msg: string;
begin
  if CurStep = ssPostInstall then
    if EnrollNow then
      MsgBox('Machine enrolee avec succes. Le service demarrera automatiquement.', mbInformation, MB_OK)
    else if EnrollResult = 2 then begin
      Msg := 'L''enrolement a echoue (code ou URL invalide/expire ?). ' +
        'Le service sera installe mais n''enverra pas de rapports tant que la machine n''est pas enrolee via l''icone de la barre des taches.';
      MsgBox(Msg, mbError, MB_OK);
    end
    else if EnrollResult = 1 then begin
      Msg := 'Reaffectation refusee. ' +
        'La machine reste rattachee a son tiers actuel; vous pouvez relancer l''enrolement via l''icone de la barre des taches.';
      MsgBox(Msg, mbInformation, MB_OK);
    end;
end;

[Run]
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "install"; Flags: runhidden; Description: "Installer le service Windows"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "start"; Flags: runhidden; Description: "Demarrer le service Windows"

[UninstallRun]
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "stop"; Flags: runhidden; RunOnceId "StopSvc"
Filename: "{app}\{#MyAppServiceExeName}"; Parameters: "remove"; Flags: runhidden; RunOnceId "RemoveSvc"

[UninstallDelete]
Type: files; Name: "{app}\agent_service.log"
