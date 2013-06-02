[Setup]

;TODO Put the application name here:
#define ApplicationName "PipTracking v1.22"

AppName    = PipTracking v1.22
AppVersion = 1.22

WizardImageFile      = sources\img\LeftIn.bmp
WizardSmallImageFile = sources\img\Top.bmp

Compression      = lzma2
SolidCompression = yes

;TODO EULA put to this file
LicenseFile      = sources\license\Public Agreement AirBionicFX.rtf

DefaultDirName     = {pf}\{#ApplicationName}
DisableDirPage     = no

DefaultGroupName = {#ApplicationName}

;TODO Directory where installer file will be generated
OutputDir          = output
;TODO Name of installer file
OutputBaseFilename = PipTracking v1.22

Uninstallable      = yes

SetupIconFile = sources\img\Install 48_48.ico
UninstallDisplayIcon = {app}\icons\Uninstall 32_32.ico



[Files]
;TODO Number of files to be copied to MetaTrader. Change if needed
#define filesTotal  2

;TODO Array of files sources to be copied to MetaTrader
#dim inFiles[filesTotal]
#define inFiles[0] "sources\PipTracking.mq4"
#define inFiles[1] "sources\PipTracking.ex4"

;TODO Output directories and names for above files inside MetaTrader directory
#dim outFiles[filesTotal]
#define outFiles[0] "experts\PipTracking v1.22.mq4"
#define outFiles[1] "experts\PipTracking v1.22.ex4"

;TODO Add or remove needed lines here is files number changes
Source: "{#inFiles[0]}"; DestDir: "{tmp}"; Flags: dontcopy
Source: "{#inFiles[1]}"; DestDir: "{tmp}"; Flags: dontcopy

; Icons:
;TODO Leave as is
Source: "sources\img\Uninstall 32_32.ico"; DestDir: "{app}\icons"
Source: "sources\img\Main.ico"; DestDir: "{app}\icons"

;TODO Files to be installed as application to ProgramFiles and Launch.
;Source: "sources\1\AM\ArbitrageManager.exe"; DestDir: "{app}"
;Source: "sources\1\AM\Pairs.dat"; DestDir: "{app}"
;Source: "sources\1\AM\languages\English.txt"; DestDir: "{app}\languages"
;Source: "sources\1\AM\languages\Russian.txt"; DestDir: "{app}\languages"

;TODO  Run (if needed remove comment):
;Source: "sources\dotNetFx40_Full_setup.exe"; DestDir: "{app}\install"; Flags: deleteafterinstall

;TODO (if needed remove comments)
;[Run]
;Filename: "{app}\install\dotNetFx40_Full_setup.exe"; Description: "Install Microsoft .Net Framework 4"; Flags: postinstall waituntilterminated


[Icons]
Name: "{group}\Uninstall {#ApplicationName}"; Filename: "{uninstallexe}"; IconFilename: "{app}\icons\Uninstall 32_32.ico";
;TODO Shortcuts for Launch menu
;Name: "{group}\ {#ApplicationName}"; Filename: "{app}\ArbitrageManager.exe"; IconFilename: "{app}\icons\Main.ico";



[Code]
type
	TNameLocation = record
  	Name     : String;
    Location : String;
  end;
  TArrayOfNameLocation = array of TNameLocation;

const
	UNINSTALL_SUBKEY    = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  MTFileName          = 'terminal.exe';
	MT4ExpertsFolder    = 'experts';
	MT4IndicatorsFolder = 'experts\indicators';
  MT4LibrariesFolder  = 'experts\libraries';
	MT5ExpertsFolder    = 'mql5\experts';
	MT5IndicatorsFolder = 'mql5\indicators';
  MT5LibrariesFolder  = 'mql5\libraries';

var
	{ Installed terminals chooser page }
	TerminalsChooserPage         : TWizardPage;
  AddCustomTerminalButton      : TNewButton;
  InstalledTerminalsCheckBoxes : TNewCheckListBox;
  InstalledTerminals                                            : TArrayOfNameLocation; 
  VersionRequired                                               : Integer;
  checkTerminalExe, checkIndicatorsFolder, checkLibrariesFolder : Boolean;



function max(const num1, num2 : Longint) : Longint;
begin
  if (num1 > num2) then Result := num1 else Result := num2;
end;



function min(const num1, num2 : Longint) : Longint;
begin
  if (num1 < num2) then Result := num1 else Result := num2;
end;



{
	Function returns array of strings where each string
	contains a location of MetaTrader terminal
}
function GetMTTerminalsLocations() : TArrayOfNameLocation;
var
	InstalledTerminals          : TArrayOfNameLocation;
	UninstallSubKeysNames       : TArrayOfString;
	CurrentSubkeyValueNames     : TArrayOfString;
	Publisher                   : String;
	InstallLocation             : String;
  DisplayName                 : String;
	i, j, k : Integer;
  nameFound, locationFound : Boolean;
  str:string;
begin
	SetArrayLength(InstalledTerminals, 0);
  
	// Check if 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' exist
  if (RegKeyExists(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY)) then begin
		// Get all subkeys to [UninstallSubKeys]
		if (RegGetSubKeyNames(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY, UninstallSubKeysNames)) then begin
			// For each of [UninstallSubKeys] get its value names to [CurrentSubkeyValueNames]
      for i := 0 to GetArrayLength(UninstallSubKeysNames) - 1 do begin
				if (RegGetValueNames(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY + '\' + UninstallSubKeysNames[i], CurrentSubkeyValueNames)) then begin
					// For each parameter in [CurrentSubkeyValueNames] check parameter name
					// and if it equals to 'Publisher' check its value. If value equals
					// to 'MetaQuotes Software Corp.' add value of parameter with name
					// 'InstallLocation' to result array [InstalledTerminals.Location]
          // and add terminal name to [InstalledTerminals.Name]
          for j := 0 to GetArrayLength(CurrentSubkeyValueNames) - 1 do begin
						if ('Publisher' = CurrentSubkeyValueNames[j]) then begin
              if (RegQueryStringValue(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY + '\' + UninstallSubKeysNames[i], CurrentSubkeyValueNames[j], Publisher)) then begin
              	Publisher := Copy(Publisher, 0, Length('MetaQuotes Software Corp.'));
                if ('MetaQuotes Software Corp.' = Publisher) then begin
                	SetArrayLength(InstalledTerminals, GetArrayLength(InstalledTerminals) + 1);
									for k := 0 to GetArrayLength(CurrentSubkeyValueNames) - 1 do begin
                  	nameFound := false;
                    locationFound := false;
                    if ('DisplayName' = CurrentSubkeyValueNames[k]) then begin
											if (RegQueryStringValue(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY + '\' + UninstallSubKeysNames[i], CurrentSubkeyValueNames[k], DisplayName)) then begin
                        InstalledTerminals[GetArrayLength(InstalledTerminals) - 1].Name := DisplayName;
                        nameFound := true;
											end;
										end else if ('InstallLocation' = CurrentSubkeyValueNames[k]) then begin
											if (RegQueryStringValue(HKEY_LOCAL_MACHINE, UNINSTALL_SUBKEY + '\' + UninstallSubKeysNames[i], CurrentSubkeyValueNames[k], InstallLocation)) then begin
												InstalledTerminals[GetArrayLength(InstalledTerminals) - 1].Location := InstallLocation;
                        locationFound := true;
											end;
										end;
                    if (nameFound and locationFound) then begin
                      break;
                    end;
									end;
								end;
							end;
							break;
						end;
					end;
				end;
			end;
		end;
	end;
  
	Result := InstalledTerminals;
end;



{
	MT4/MT5 detect
		params:
			checkTerminalExe        -- check if [terminal.exe] file exists
			checkIndicatorsFolder   -- check if [indicators] folder exists
			checkLibrariesFolder    -- check if [libraries] folder exists
		returns:
			>0   -- version of MT
			 0   -- version of MT have not been determined
			-1   -- specified [installDir] folder doesn't exist
			-2   -- none of [experts] folders of MT4/MT5 exists
			-3   -- file [terminal.exe] doesn't exist
			-4   -- none of [indicators] folders of MT4/MT5 exists
			-5   -- none of [libraries] folders of MT4/MT5 exists
}
function GetMTTerminalVersionByLocation(const location : String; const checkTerminalExe, checkIndicatorsFolder, checkLibrariesFolder : Boolean) : Integer;
var
	Version : Integer;
	MT4FolderExists : Boolean;
  MT5FolderExists : Boolean;
begin
	Version := 0;
  
	// Check if [location] directory exists
  if (not DirExists(location)) then begin
    Result := -1;   // location folder doesn't exist
    Exit;
  end;
  
  // Check MT4/MT5 'experts' folder
  MT4FolderExists := DirExists(location + '\' + MT4ExpertsFolder);
  MT5FolderExists := DirExists(location + '\' + MT5ExpertsFolder);
  if (MT4FolderExists and (not MT5FolderExists)) then begin
  	Version := 4;
  end else if ((not MT4FolderExists) and MT5FolderExists) then begin
    Version := 5;
  end else if ((not MT4FolderExists) and (not MT5FolderExists)) then begin
    Result := -2;   // none of 'experst' folders exists
    Exit;
  end;
  
  // Check for 'terminal.exe' if needed
  if (checkTerminalExe) then begin
    if (not FileExists(location + '\' + MTFileName)) then begin
      Result := -3;   // 'terminal.exe' doesn't exist
      Exit;
    end;
  end;
  
  // Check for 'indicators' folder
  if (checkIndicatorsFolder) then begin
    case (Version) of
      4: 
      	if (not DirExists(location + '\' + MT4IndicatorsFolder)) then begin
        	Result := -4;   // 'indicators' folder doesn't exist
          Exit;
      	end;
      5:
      	if (not DirExists(location + '\' + MT5IndicatorsFolder)) then begin
        	Result := -4;   // 'indicators' folder doesn't exist
          Exit;
      	end;
    end;
  end;
  
  // Check for 'libraries' folder
  if (checkLibrariesFolder) then begin
    case (Version) of
      4: 
      	if (not DirExists(location + '\' + MT4LibrariesFolder)) then begin
        	Result := -5;   // 'libraries' folder doesn't exist
          Exit;
      	end;
      5:
      	if (not DirExists(location + '\' + MT5LibrariesFolder)) then begin
        	Result := -5;   // 'libraries' folder doesn't exist
          Exit;
      	end;
    end;
  end;
  
  // If all OK (all files checked and exist and all directories also checked and exits) return [Version]
  Result := Version;
end;



function FilterMTTerminalLocationsByVersion(const terminals : TArrayOfNameLocation; const version : Integer; const checkTerminalExe, checkIndicatorsFolder, checkLibrariesFolder : Boolean) : TArrayOfNameLocation;
var
	FilteredLocations : TArrayOfNameLocation;
  i : Integer;
begin
	SetArrayLength(FilteredLocations, 0);
  
  for i := 0 to GetArrayLength(terminals) - 1 do begin
    if (version = GetMTTerminalVersionByLocation(terminals[i].Location, checkTerminalExe, checkIndicatorsFolder, checkLibrariesFolder)) then begin
      SetArrayLength(FilteredLocations,  GetArrayLength(FilteredLocations) + 1);
      FilteredLocations[GetArrayLength(FilteredLocations) - 1] := terminals[i]; 
    end;
  end;
  
  Result := FilteredLocations;
end;



procedure AddCustomTerminalButtonOnClick(Sender: TObject);
var
  customTerminalLocation : String;
begin
  if (BrowseForFolder( 'Select a folder in a list below, then click OK.',
      // Alternate info text:
      //'Please select a folder where MetaTrader terminal is located (a directory where "terminal.exe" file located.)', 
      customTerminalLocation,
      false)) then begin
    InstalledTerminalsCheckBoxes.AddCheckBox(customTerminalLocation, '', 0, True, True, False, True, nil);
    SetArrayLength(InstalledTerminals, GetArrayLength(InstalledTerminals) + 1);
    InstalledTerminals[GetArrayLength(InstalledTerminals) - 1].Name     := customTerminalLocation;
    InstalledTerminals[GetArrayLength(InstalledTerminals) - 1].Location := customTerminalLocation; 
  end;
end;



{ -----------------------------------------------------------------------------
 CREATE PAGE THAT LET USER CHOOSE TERMINAL FOLDERS WHERE APP WILL BE INSTALLED
----------------------------------------------------------------------------- }
procedure CreateTerminalChooserPage();
var
	i : Integer;
  Terminals : TArrayOfNameLocation;
  InfoLabel : TLabel;
begin
	{ Get folders of installed MetaTrader terminals }
  VersionRequired       := 4;
	checkTerminalExe      := true;
  checkIndicatorsFolder := true; 
  checkLibrariesFolder  := true;
  SetArrayLength(Terminals, 0);
  
  Terminals := FilterMTTerminalLocationsByVersion(GetMTTerminalsLocations(), VersionRequired, checkTerminalExe, checkIndicatorsFolder, checkLibrariesFolder);
  InstalledTerminals := Terminals;
  
  { Create page }
	TerminalsChooserPage := CreateCustomPage(wpReady, 'Select Destination Locations', ExpandConstant('Where should {#ApplicationName} be installed?'));
  
  { Add info labels }
  InfoLabel := TLabel.Create(TerminalsChooserPage);
  InfoLabel.Caption := ExpandConstant('Setup will install {#ApplicationName} into the following folders.' + #13#10 
      + 'To continue, click Next. If you would like to select a different folder, clock Browse.');
  InfoLabel.Parent := TerminalsChooserPage.Surface;
  
  { Add butthon that allows user to add custon MT locations }
  AddCustomTerminalButton := TNewButton.Create(TerminalsChooserPage);
  AddCustomTerminalButton.Caption := 'Browse...';
  AddCustomTerminalButton.Top := TerminalsChooserPage.SurfaceHeight - AddCustomTerminalButton.Height - 5;
  AddCustomTerminalButton.OnClick := @AddCustomTerminalButtonOnClick;
  AddCustomTerminalButton.Parent := TerminalsChooserPage.Surface;
  
	{ Add CheckBoxes }
  InstalledTerminalsCheckBoxes := TNewCheckListBox.Create(TerminalsChooserPage);
  InstalledTerminalsCheckBoxes.Top := InfoLabel.Top + InfoLabel.Height + 10;
  InstalledTerminalsCheckBoxes.Width := TerminalsChooserPage.SurfaceWidth;
  InstalledTerminalsCheckBoxes.Height := TerminalsChooserPage.SurfaceHeight - AddCustomTerminalButton.Height - InfoLabel.Height  - 5 - 10 - 10;
  InstalledTerminalsCheckBoxes.Parent := TerminalsChooserPage.Surface;
  for i := 0 to GetArrayLength(Terminals) - 1 do begin
    InstalledTerminalsCheckBoxes.AddCheckBox(Terminals[i].Name + ' (' + Terminals[i].Location + ')', '', 0, True, True, False, True, nil);
	end;
end;



procedure InitializeWizard();
begin
	CreateTerminalChooserPage();
end;



function GetFileFromPath(const Path : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := Length(Path) - 1 downto 0 do begin
    if ((Path[i] = '\') or (Path[i] = '/')) then begin
      Result := Copy(Path, i + 1, Length(Path));
      Exit; 
    end; 
  end;
end;



function GetDirFromPath(const Path : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := Length(Path) - 1 downto 0 do begin
    if ((Path[i] = '\') or (Path[i] = '/')) then begin
      Result := Copy(Path, 0, i - 1);
      Exit; 
    end; 
  end;
end;



function NextButtonClick(CurPageID: Integer): Boolean;
var
  i, j  : Integer;
  FindRec : TFindRec;
  s, newFile: string;
  b : Boolean;
begin
  if (TerminalsChooserPage.ID = CurPageID) then begin
  
//TODO  Add or remove needed lines here 
    ExtractTemporaryFile(GetFileFromPath(ExpandConstant('{#inFiles[0]}')));
    ExtractTemporaryFile(GetFileFromPath(ExpandConstant('{#inFiles[1]}')));     
    
    for i := 0 to GetArrayLength(InstalledTerminals) - 1 do begin
      if (InstalledTerminalsCheckBoxes.Checked[i]) then begin
        // Copy file #1
        if (not DirExists(InstalledTerminals[i].Location + '\' + GetDirFromPath(ExpandConstant('{#outFiles[0]}')))) then begin
          CreateDir(InstalledTerminals[i].Location + '\' + GetDirFromPath(ExpandConstant('{#outFiles[0]}')));
        end;
        if (FileCopy(ExpandConstant('{tmp}') + '\' + GetFileFromPath(ExpandConstant('{#inFiles[0]}')), InstalledTerminals[i].Location + '\' + ExpandConstant('{#outFiles[0]}'), false)) then begin        
           RegWriteStringValue(HKEY_LOCAL_MACHINE, ExpandConstant(UNINSTALL_SUBKEY + '\{#ApplicationName}'), 'InstallLocation_1_' + IntToStr(i), InstalledTerminals[i].Location + '\' + ExpandConstant('{#outFiles[0]}'));
        end;
        
        // Copy file #2
        if (not DirExists(InstalledTerminals[i].Location + '\' + GetDirFromPath(ExpandConstant('{#outFiles[1]}')))) then begin
          CreateDir(InstalledTerminals[i].Location + '\' + GetDirFromPath(ExpandConstant('{#outFiles[1]}')));
        end;
        if FileCopy(ExpandConstant('{tmp}') + '\' + GetFileFromPath(ExpandConstant('{#inFiles[1]}')), InstalledTerminals[i].Location + '\' + ExpandConstant('{#outFiles[1]}'), false) then begin
          RegWriteStringValue(HKEY_LOCAL_MACHINE, ExpandConstant(UNINSTALL_SUBKEY + '\{#ApplicationName}'), 'InstallLocation_2_' + IntToStr(i), InstalledTerminals[i].Location + '\' + ExpandConstant('{#outFiles[1]}'));
        end; 
         
       end;               
    end;
  end;
  
  Result := true;
end;



{ -----------------------------------------------------------------------------
 UNINSTALL CODE
----------------------------------------------------------------------------- }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  i : Integer;
  ValueNames : TArrayOfString;
  FileInstallPath : String;
begin
  if (RegGetValueNames(HKEY_LOCAL_MACHINE, ExpandConstant(UNINSTALL_SUBKEY + '\{#ApplicationName}'), ValueNames)) then begin
    for i := 0 to GetArrayLength(ValueNames) - 1 do begin
      if (RegQueryStringValue(HKEY_LOCAL_MACHINE,  ExpandConstant(UNINSTALL_SUBKEY + '\{#ApplicationName}'), ValueNames[i], FileInstallPath)) then begin
        if (DeleteFile(FileInstallPath)) then begin
          RegDeleteValue(HKEY_LOCAL_MACHINE, ExpandConstant(UNINSTALL_SUBKEY + '\{#ApplicationName}'), ValueNames[i]);        end;
      end;
    end;
  end;
  
end;

