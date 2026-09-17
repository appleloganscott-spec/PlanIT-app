unit SignUp;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FireDAC.Comp.Client, Data.DB;

type
  TfrmSignUp = class(TForm)
    lblSignUpHeader: TLabel;
    edtNewUsername: TEdit;
    btnSignUp: TButton;
    btnBackToLogin: TButton;
    StyleBook1: TStyleBook;
    edtNewPassword: TEdit;
    edtConfirmPassword: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnSignUpClick(Sender: TObject);
    procedure btnBackToLoginClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSignUp: TfrmSignUp;

implementation

{$R *.fmx}

uses Login;

procedure TfrmSignUp.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.Hide;
  if Assigned(frmLogin) then
    frmLogin.Show;
end;

procedure TfrmSignUp.FormCreate(Sender: TObject);
begin
  Self.Position := TFormPosition.ScreenCenter;
  edtNewPassword.Password := True;
  edtConfirmPassword.Password := True;
  edtNewUsername.TextPrompt := 'New Username';
  edtNewPassword.TextPrompt := 'New Password';
  edtConfirmPassword.TextPrompt := 'Confirm Password';
end;

procedure TfrmSignUp.btnSignUpClick(Sender: TObject);
var
  sUser, sPass, sConfirmPass: String;
begin
  sUser := Trim(edtNewUsername.Text);
  sPass := Trim(edtNewPassword.Text);
  sConfirmPass := Trim(edtConfirmPassword.Text);

  if sUser = '' then
  begin
    ShowMessage('Please enter a username to register.');
    if edtNewUsername.CanFocus then
      edtNewUsername.SetFocus;
    Exit;
  end;

  if sPass = '' then
  begin
    ShowMessage('Please enter a password.');
    if edtNewPassword.CanFocus then
      edtNewPassword.SetFocus;
    Exit;
  end;

  if sConfirmPass = '' then
  begin
    ShowMessage('Please confirm your password.');
    if edtConfirmPassword.CanFocus then
      edtConfirmPassword.SetFocus;
    Exit;
  end;

  // making sure both password boxes match before trying to save anything
  if sPass <> sConfirmPass then
  begin
    ShowMessage('Passwords do not match. Please re-enter your password.');
    edtConfirmPassword.Text := '';
    if edtConfirmPassword.CanFocus then
      edtConfirmPassword.SetFocus;
    Exit;
  end;

  if not Assigned(frmLogin) or not frmLogin.FDConnection1.Connected then
  begin
    ShowMessage('Database connection is inactive.');
    Exit;
  end;

  try
    // checking the database with parameters to see if the username already exists
    frmLogin.FDQuery1.Close;
    frmLogin.FDQuery1.SQL.Text := 'SELECT Username FROM tblUsers WHERE Username = :User';
    frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
    frmLogin.FDQuery1.Open;

    if not frmLogin.FDQuery1.IsEmpty then
    begin
      ShowMessage('Username already exists. Please pick a different username.');
      if edtNewUsername.CanFocus then
        edtNewUsername.SetFocus;
      Exit;
    end;

    // inserting the new account into the database with starting balances set to zero
    frmLogin.FDQuery1.Close;
    frmLogin.FDQuery1.SQL.Text :=
      'INSERT INTO tblUsers (Username, [Password], CurrentBalance, InitialBalance) ' +
      'VALUES (:User, :Pass, ''0.00'', ''0.00'')';
    frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
    frmLogin.FDQuery1.ParamByName('Pass').AsString := sPass;
    frmLogin.FDQuery1.ExecSQL;

    ShowMessage('Account created successfully! Returning to login.');

    edtNewUsername.Text := '';
    edtNewPassword.Text := '';
    edtConfirmPassword.Text := '';

    Self.Hide;
    frmLogin.Show;
  except
    on E: Exception do
      ShowMessage('Error creating account: ' + E.Message);
  end;
end;

procedure TfrmSignUp.btnBackToLoginClick(Sender: TObject);
begin
  edtNewUsername.Text := '';
  edtNewPassword.Text := '';
  edtConfirmPassword.Text := '';

  Self.Hide;
  if Assigned(frmLogin) then
    frmLogin.Show;
end;

end.
