unit History;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Objects,
  FMX.Memo.Types, FireDAC.Comp.Client, Data.DB;

type
  TfrmHistory = class(TForm)
    rchHistory: TMemo;
    btnClearHistory: TButton;
    StyleBook1: TStyleBook;
    procedure btnClearHistoryClick(Sender: TObject);
    procedure btnBackFromHistoryClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmHistory: TfrmHistory;

implementation

{$R *.fmx}

uses PlanIT, Login;

procedure TfrmHistory.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.Hide;
  if Assigned(frmPlanIT) then
    frmPlanIT.Show;
end;

procedure TfrmHistory.FormCreate(Sender: TObject);
begin
  Position := TFormPosition.ScreenCenter;
end;

procedure TfrmHistory.btnClearHistoryClick(Sender: TObject);
var
  sUser: String;
begin
  { 1. Resolve active username from PlanIT form }
  // grabbing the username from the main labels and cutting out the "Welcome" part with copy and trim
  sUser := Trim(frmPlanIT.lblCurrentAccount.Text);
  if sUser = '' then
  begin
    sUser := Trim(frmPlanIT.lblWelcomeUser.Text);
    if SameText(Copy(sUser, 1, 9), 'Welcome, ') then
      sUser := Trim(Copy(sUser, 10, Length(sUser)))
    else if SameText(Copy(sUser, 1, 8), 'Welcome ') then
      sUser := Trim(Copy(sUser, 9, Length(sUser)));
  end;

  if (sUser = '') or SameText(sUser, 'User') then
  begin
    ShowMessage('No active user account found.');
    Exit;
  end;

  { 2. Delete user expenses directly from tblExpenses }
  // using a parameter (:User) in the sql query instead of writing the name directly so it doesn't break
  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text := 'DELETE FROM tblExpenses WHERE Username = :User';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.ExecSQL;

      rchHistory.Lines.Clear;
      rchHistory.Lines.Add('=== TRANSACTION HISTORY FOR ' + UpperCase(sUser) + ' ===');
      rchHistory.Lines.Add('No transaction records found.');

      ShowMessage('Transaction history cleared successfully from database.');
    except
      on E: Exception do
        ShowMessage('Failed to clear database history: ' + E.Message);
    end;
  end
  else
  begin
    ShowMessage('Database connection is inactive.');
  end;
end;

procedure TfrmHistory.btnBackFromHistoryClick(Sender: TObject);
begin
  rchHistory.Lines.Clear;
  Self.Hide;
  if Assigned(frmPlanIT) then
    frmPlanIT.Show;
end;

end.
