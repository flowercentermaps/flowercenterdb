#define MyAppName "Flower Center CRM"
#define MyAppVersion "1.0.3"
#define MyAppPublisher "Flower Center"
#define MyAppURL "https://flowercenter.ae"
#define MyAppExeName "FlowerCenterCrm.exe"
#define MyAppSourceDir "..\..\build\windows\x64\runner\Release"

[Setup]
; Keep this AppId unchanged forever for upgrades/uninstall continuity
AppId={{A3F7B2C1-4D5E-4F6A-8B9C-0D1E2F3A4B5C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

OutputDir=.\output
OutputBaseFilename=FlowerCenterCRM-Setup-{#MyAppVersion}

SetupIconFile=..\runner\resources\app_icon.ico

Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

CloseApplications=yes
CloseApplicationsFilter=*{#MyAppExeName}

PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Copy the entire Flutter Windows Release output
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;