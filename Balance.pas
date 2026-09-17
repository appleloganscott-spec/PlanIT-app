unit Balance;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation;

type
  TfrmBalance = class(TForm)
    lblHeader: TLabel;
    lblAmount: TLabel;
    lblCurrentBalance: TLabel;
    edtBalanceEditAmount: TEdit;
    Panel1: TPanel;
    btnCloseBalance: TButton;
    btnUpdateBalance: TCornerButton;
    RadioBalance: TGroupBox;
    RadioAddFunds: TRadioButton;
    RadioRemoveFunds: TRadioButton;
    StyleBook1: TStyleBook;
    procedure FormShow(Sender: TObject);
    procedure btnUpdateBalanceClick(Sender: TObject);
    procedure btnCloseBalanceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmBalance: TfrmBalance;

implementation

{$R *.fmx}

uses PlanIT, Login;

procedure TfrmBalance.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Self.Hide;
  if Assigned(frmPlanIT) then
    frmPlanIT.Show;
end;

procedure TfrmBalance.FormCreate(Sender: TObject);
begin
  // Centers the balance adjustment form on the screen upon creation
  Position := TFormPosition.ScreenCenter;
end;

procedure TfrmBalance.FormShow(Sender: TObject);
begin
  edtBalanceEditAmount.Text := '';

  // Default to adding funds when the form opens
  if Assigned(RadioAddFunds) then
    RadioAddFunds.IsChecked := True;

  // Dynamically displays the current balance using the active currency symbol
  if Assigned(lblCurrentBalance) and Assigned(frmPlanIT) then
    lblCurrentBalance.Text := 'Current Balance: ' + frmPlanIT.sCurrencySymbol +
      FloatToStrF(frmPlanIT.rCurrentBalance, ffFixed, 8, 2);

  if edtBalanceEditAmount.CanFocus then
    edtBalanceEditAmount.SetFocus;
end;

procedure TfrmBalance.btnUpdateBalanceClick(Sender: TObject);
var
  rAmount, rRate: Real;
  iCode: Integer;
  sCleanInput: String;
begin
  // Cleans input by stripping currency symbols, spaces, and standardizing decimal separators
  sCleanInput := Trim(edtBalanceEditAmount.Text);
  sCleanInput := StringReplace(sCleanInput, frmPlanIT.sCurrencySymbol, '', [rfReplaceAll, rfIgnoreCase]);
  sCleanInput := StringReplace(sCleanInput, ' ', '', [rfReplaceAll]);
  sCleanInput := StringReplace(sCleanInput, ',', '.', [rfReplaceAll]);

  Val(sCleanInput, rAmount, iCode);

  // Validates that the input is a valid positive number
  if (sCleanInput = '') or (iCode <> 0) or (rAmount <= 0) then
  begin
    ShowMessage('Please enter a valid positive numeric amount.');
    if edtBalanceEditAmount.CanFocus then
      edtBalanceEditAmount.SetFocus;
    Exit;
  end;

  // Checks if the user selected to remove funds and ensures they have enough balance
  if Assigned(RadioRemoveFunds) and RadioRemoveFunds.IsChecked then
  begin
    if rAmount > frmPlanIT.rCurrentBalance then
    begin
      ShowMessage('Cannot remove funds! Amount exceeds your current balance.');
      Exit;
    end;
    rAmount := -rAmount;
  end;

  // Retrieves the current exchange rate conversion factor relative to ZAR
  rRate := frmPlanIT.GetRateFromZAR(frmPlanIT.sCurrencySymbol);

  // Updates both local currency balances and the underlying ZAR base amounts
  frmPlanIT.rCurrentBalance := frmPlanIT.rCurrentBalance + rAmount;
  frmPlanIT.rBaseCurrentBalanceZAR := frmPlanIT.rBaseCurrentBalanceZAR + (rAmount / rRate);

  // Sets initial balance automatically if it hasn't been defined yet
  if frmPlanIT.rInitialBalance <= 0 then
  begin
    frmPlanIT.rInitialBalance := frmPlanIT.rCurrentBalance;
    frmPlanIT.rBaseInitialBalanceZAR := frmPlanIT.rBaseCurrentBalanceZAR;
  end;

  // Persists changes to the database and refreshes main form labels
  frmPlanIT.SaveUserBalanceToDB;
  frmPlanIT.UpdateLabels;

  ShowMessage('Balance updated successfully!');

  edtBalanceEditAmount.Text := '';
  Self.Hide;
  if Assigned(frmPlanIT) then
    frmPlanIT.Show;
end;

procedure TfrmBalance.btnCloseBalanceClick(Sender: TObject);
begin
  edtBalanceEditAmount.Text := '';
  Self.Hide;
  if Assigned(frmPlanIT) then
    frmPlanIT.Show;
end;

end.
