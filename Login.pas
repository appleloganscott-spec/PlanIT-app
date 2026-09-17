unit Login;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Objects,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MSAcc, FireDAC.Phys.MSAccDef, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Phys.ODBCBase;

type
  TfrmLogin = class(TForm)
    edtPassword: TEdit;
    edtUser: TEdit;
    FDPhysMSAccessDriverLink1: TFDPhysMSAccessDriverLink;
    Image1: TImage;
    lblCreateOne: TLabel;
    lblSignUp: TLabel;
    StyleBook1: TStyleBook;
    FDQuery1: TFDQuery;
    FDConnection1: TFDConnection;
    btnLogin: TButton;
    btnHelp: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure lblCreateOneClick(Sender: TObject);
    procedure edtPasswordKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    { Private declarations }
    procedure ConnectToDatabase;
  public
    { Public declarations }
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.fmx}

uses System.IOUtils, PlanIT, SignUp;

procedure TfrmLogin.ConnectToDatabase;
var
  sExeDir, sFolder, sDbPath: String;
  bFound: Boolean;
  i: Integer;

  function FindDbInFolder(const AFolder: String): Boolean;
  begin
    if FileExists(TPath.Combine(AFolder, 'PlanIT_Database.accdb')) then
    begin
      sDbPath := TPath.Combine(AFolder, 'PlanIT_Database.accdb');
      Exit(True);
    end;
    if FileExists(TPath.Combine(AFolder, 'PlanIT_Database.mdb')) then
    begin
      sDbPath := TPath.Combine(AFolder, 'PlanIT_Database.mdb');
      Exit(True);
    end;
    Result := False;
  end;

begin
  sExeDir := ExtractFilePath(ParamStr(0));
  sDbPath := '';
  bFound := False;

  // loops through folders starting from where the app runs and goes up through parent directories to find the database file automatically so it doesn't break on another PC
  bFound := FindDbInFolder(sExeDir) or
            FindDbInFolder(TPath.Combine(sExeDir, 'Database'));

  if not bFound then
  begin
    sFolder := ExcludeTrailingPathDelimiter(sExeDir);
    for i := 1 to 5 do
    begin
      sFolder := TPath.GetDirectoryName(sFolder);
      if sFolder = '' then Break;

      bFound := FindDbInFolder(sFolder) or
                FindDbInFolder(TPath.Combine(sFolder, 'Database'));

      if bFound then Break;
    end;
  end;

  if not bFound then
  begin
    ShowMessage('Database file could not be found.' + sLineBreak +
      'Searched in: ' + TPath.Combine(sExeDir, 'Database'));
    Exit;
  end;

  try
    FDConnection1.Connected := False;
    FDConnection1.Params.Clear;
    FDConnection1.Params.Add('DriverID=MSAcc');
    FDConnection1.Params.Add('Database=' + sDbPath);

    // explicit 64-bit ACE OLEDB Provider parameters
    FDConnection1.Params.Add('StringFormat=Unicode');
    FDConnection1.Params.Add('MSAccCLX=Microsoft.ACE.OLEDB.12.0');

    FDConnection1.Connected := True;
  except
    on E: Exception do
      ShowMessage('Database connection failed:' + sLineBreak + E.Message);
  end;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  Caption := 'Login';
  Position := TFormPosition.ScreenCenter;
  edtPassword.Password := True;
  edtUser.SetFocus;
  edtUser.TextPrompt := 'Username';
  edtPassword.TextPrompt := 'Password';
  ConnectToDatabase;

  edtPassword.OnKeyDown := edtPasswordKeyDown;
end;

procedure TfrmLogin.edtPasswordKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    btnLoginClick(btnLogin);
  end;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
var
  sUser, sPass, sBalText, sInitText: String;
  rBal, rInit: Real;
  iCode: Integer;
begin
  sUser := Trim(edtUser.Text);
  sPass := Trim(edtPassword.Text);

  if (sUser = '') or (sPass = '') then
  begin
    ShowMessage('Please enter both username and password.');
    Exit;
  end;

  if not FDConnection1.Connected then
    ConnectToDatabase;

  try
    // uses parameters (:User and :Pass) to safely check the database table without messing up or getting SQL injection
    FDQuery1.Close;
    FDQuery1.SQL.Text := 'SELECT * FROM tblUsers WHERE Username = :User AND [Password] = :Pass';
    FDQuery1.ParamByName('User').AsString := sUser;
    FDQuery1.ParamByName('Pass').AsString := sPass;
    FDQuery1.Open;

    if not FDQuery1.IsEmpty then
    begin
      if Assigned(frmPlanIT) then
      begin
        frmPlanIT.lblCurrentAccount.Text := sUser;
        frmPlanIT.lblWelcomeUser.Text := 'Welcome, ' + sUser;

        // replaces commas with dots so delphi's Val command can read the balance numbers properly without crashing
        sBalText := Trim(FDQuery1.FieldByName('CurrentBalance').AsString);
        sBalText := StringReplace(sBalText, ',', '.', [rfReplaceAll]);
        Val(sBalText, rBal, iCode);
        if iCode <> 0 then rBal := 0.0;

        sInitText := Trim(FDQuery1.FieldByName('InitialBalance').AsString);
        sInitText := StringReplace(sInitText, ',', '.', [rfReplaceAll]);
        Val(sInitText, rInit, iCode);
        if iCode <> 0 then rInit := 0.0;

        frmPlanIT.rBaseCurrentBalanceZAR := rBal;
        frmPlanIT.rBaseInitialBalanceZAR := rInit;
        frmPlanIT.RecalculateForCurrency;

        Self.Hide;
        frmPlanIT.Show;
        frmPlanIT.LoadUserStatsFromDB;
      end;
    end
    else
    begin
      ShowMessage('Invalid username or password.');
    end;
  except
    on E: Exception do
      ShowMessage('Login error: ' + E.Message);
  end;
end;

procedure TfrmLogin.btnHelpClick(Sender: TObject);
begin
  ShowMessage('PlanIT Help:' + sLineBreak + sLineBreak +
    '1. Enter your Username and Password to log in.' + sLineBreak +
    '2. Click "Create One!" if you do not have an account yet.' + sLineBreak +
    '3. Press ENTER while in the password field to log in quickly.');
end;

procedure TfrmLogin.lblCreateOneClick(Sender: TObject);
begin
  Self.Hide;
  if Assigned(frmSignUp) then
  begin
    frmSignUp.Show;
    frmSignUp.edtNewUsername.SetFocus;
  end;
end;

end.
