unit PlanIT;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils, System.Math, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TabControl, FMX.StdCtrls, FMX.Edit, FMX.ListBox, FMX.Memo, FMX.Objects,
  FMX.Controls.Presentation, FMX.Memo.Types, FMX.ScrollBox, System.Math.Vectors,
  FMX.Controls3D, FMX.Layers3D, FMX.DateTimeCtrls, FMX.EditBox, FMX.SpinBox,
  FMX.ComboEdit, FMX.Layouts, FMX.Ani, FMX.Effects, FireDAC.Comp.Client, Data.DB;

type
  TfrmPlanIT = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    lblWelcomeUser: TLabel;
    btnFunds: TButton;
    lblExpense: TLabel;
    edtExpense: TEdit;
    lblCategory: TLabel;
    cmbCategory: TComboBox;
    btnAddExpense: TButton;
    btnCalculateBudget: TButton;
    btnResetBudget: TButton;
    redOutput: TMemo;
    btnExport: TButton;
    btnHistory: TButton;
    btnGoBack: TButton;
    lblAccount: TLabel;
    lblCurrentAccount: TLabel;
    lblFormat: TLabel;
    lblFormatCurrency: TLabel;
    ComboBox1: TComboBox;
    btnSave: TButton;
    imgSettingsLogo: TImage;
    SaveDialog1: TSaveDialog;

    btnCalculateGoal: TButton;
    btnResetGoalReset: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    lblGoalAmount: TLabel;
    lblGoalResult: TLabel;
    StyleBook1: TStyleBook;
    grpDash: TGroupBox;
    grpIE: TGroupBox;
    lblCurrentBalance: TLabel;
    lblEditFunds: TLabel;
    lblDate: TLabel;
    DateEdit1: TDateEdit;
    Image3D1: TImage3D;

    lblHighestExpense: TLabel;
    lblHighestExpenseOut: TLabel;
    lblMostFrequent: TLabel;
    lblMostFrequentExpenseOut: TLabel;

    lblGoaLinsight: TLabel;
    edtGoalInsight: TEdit;
    grpGoals: TGroupBox;
    grpInterest: TGroupBox;
    lblDeposit: TLabel;
    lblTime: TLabel;
    lblRate: TLabel;
    btnCalculateInterest: TButton;
    btnInterestReset: TButton;
    edtDepositAmount: TEdit;
    cmbTime: TComboBox;
    cmbRate: TComboEdit;
    memIntOutput: TMemo;
    lblDangerZone: TLabel;
    lblDeleteAcc: TLabel;
    btnDeleteAccount: TButton;
    lblFYI: TLabel;
    btnReloadFact: TButton;
    Image1: TImage;
    FloatAnimation1: TFloatAnimation;
    ShadowEffect1: TShadowEffect;

    procedure FormCreate(Sender: TObject);
    procedure btnEditFundsClick(Sender: TObject);
    procedure btnFundsClick(Sender: TObject);
    procedure btnAddExpenseClick(Sender: TObject);
    procedure btnCalculateBudgetClick(Sender: TObject);
    procedure btnResetBudgetClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnHistoryClick(Sender: TObject);
    procedure btnGoBackClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCalculateGoalClick(Sender: TObject);
    procedure btnResetGoalResetClick(Sender: TObject);
    procedure btnCalculateInterestClick(Sender: TObject);
    procedure btnInterestResetClick(Sender: TObject);
    procedure btnDeleteAccountClick(Sender: TObject);
    procedure btnReloadFactClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    arrCategories: array[1..50] of String;
    arrCategoryTotals: array[1..50] of Real;
    arrCategoryCounts: array[1..50] of Integer;
    iCategoryCount: Integer;
    rTotalExpenses: Real;
    FYIFacts: TStringList;

    // Local queue for expenses before budget calculation
    arrPendingCategories: array[1..100] of String;
    arrPendingAmounts: array[1..100] of Real;
    arrPendingDates: array[1..100] of String;
    iPendingCount: Integer;

    procedure ClearCategoryArrays;
    procedure ClearPendingExpenses;
    procedure UpdateFYIFact;
    procedure PopulateFYIFacts;
    procedure CommitPendingExpensesToDB;
  public
    { Public declarations }
    rBaseCurrentBalanceZAR: Real;
    rBaseInitialBalanceZAR: Real;
    rCurrentBalance: Real;
    rInitialBalance: Real;
    sCurrencySymbol: String;

    function GetActiveUsername: String;
    function GetRateFromZAR(const sSymbol: String): Real;
    procedure RecalculateForCurrency;
    procedure UpdateLabels;
    procedure LoadUserStatsFromDB;
    procedure SaveUserBalanceToDB;
  end;

var
  frmPlanIT: TfrmPlanIT;

implementation

{$R *.fmx}

uses Login, History, Balance;

function TfrmPlanIT.GetActiveUsername: String;
var
  sUser: String;
  iPos: Integer;
begin
  sUser := Trim(lblCurrentAccount.Text);

  if sUser = '' then
  begin
    sUser := Trim(lblWelcomeUser.Text);

    iPos := Pos('Welcome, ', sUser);
    if iPos > 0 then
      sUser := Trim(Copy(sUser, iPos + 9, Length(sUser) - 8));

    iPos := Pos('Welcome ', sUser);
    if iPos > 0 then
      sUser := Trim(Copy(sUser, iPos + 8, Length(sUser) - 7));
  end;

  Result := sUser;
end;

procedure TfrmPlanIT.ClearCategoryArrays;
var
  I: Integer;
begin
  iCategoryCount := 0;
  rTotalExpenses := 0.0;
  for I := 1 to 50 do
  begin
    arrCategories[I] := '';
    arrCategoryTotals[I] := 0.0;
    arrCategoryCounts[I] := 0;
  end;
end;

procedure TfrmPlanIT.ClearPendingExpenses;
var
  I: Integer;
begin
  iPendingCount := 0;
  for I := 1 to 100 do
  begin
    arrPendingCategories[I] := '';
    arrPendingAmounts[I] := 0.0;
    arrPendingDates[I] := '';
  end;
end;

procedure TfrmPlanIT.PopulateFYIFacts;
begin
  if not Assigned(FYIFacts) then
    FYIFacts := TStringList.Create;

  FYIFacts.Clear;
  FYIFacts.Add('Did you know? The first paper money was used in China during the Tang Dynasty over 1,000 years ago.');
  FYIFacts.Add('Did you know? Small savings add up! Saving just R10 a day accumulates to R3,650 a year.');
  FYIFacts.Add('Did you know? The "50/30/20 Rule" suggests allocation: 50% for Needs, 30% for Wants, and 20% for Savings.');
  FYIFacts.Add('Did you know? Compound interest earns growth on both your initial deposit and previously earned interest.');
  FYIFacts.Add('Did you know? Setting up an emergency fund covering 3 to 6 months of expenses prevents debt during crises.');
  FYIFacts.Add('Did you know? Tracking small cash daily purchases helps stop "lifestyle creep" from eating your budget.');
  FYIFacts.Add('Did you know? Paying off high-interest debt first saves you significantly more money over time.');
  FYIFacts.Add('Did you know? The South African Rand (ZAR) was introduced in 1961, replacing the South African Pound.');
  FYIFacts.Add('Did you know? Automating your savings transfers on payday ensures you always save before spending.');
  FYIFacts.Add('Did you know? Inflation reduces purchasing power, making savings interest rates essential to outpace it.');
  FYIFacts.Add('Did you know? A credit score reflects your loan repayment reliability, influencing future interest rates.');
  FYIFacts.Add('Did you know? Reviewing monthly recurring subscriptions helps identify unnecessary automated costs.');
end;

procedure TfrmPlanIT.UpdateFYIFact;
begin
  if Assigned(FYIFacts) and (FYIFacts.Count > 0) and Assigned(lblFYI) then
    lblFYI.Text := FYIFacts[Random(FYIFacts.Count)];
end;

function TfrmPlanIT.GetRateFromZAR(const sSymbol: String): Real;
begin
  if SameText(sSymbol, 'R') then Result := 1.0
  else if SameText(sSymbol, '£') then Result := 1.0 / 23.25
  else if SameText(sSymbol, '$') then Result := 1.0 / 18.20
  else if SameText(sSymbol, '€') then Result := 1.0 / 19.60
  else if SameText(sSymbol, '¥') then Result := 8.25
  else Result := 1.0;
end;

procedure TfrmPlanIT.RecalculateForCurrency;
var
  rRate: Real;
begin
  rRate := GetRateFromZAR(sCurrencySymbol);
  rCurrentBalance := rBaseCurrentBalanceZAR * rRate;
  rInitialBalance := rBaseInitialBalanceZAR * rRate;
end;

procedure TfrmPlanIT.UpdateLabels;
begin
  if Assigned(lblCurrentBalance) then
    lblCurrentBalance.Text := 'Current Balance: ' + sCurrencySymbol + FloatToStrF(rCurrentBalance, ffFixed, 8, 2);

  if Assigned(lblExpense) then
    lblExpense.Text := 'Expense Amount (' + sCurrencySymbol + '):';
end;

procedure TfrmPlanIT.SaveUserBalanceToDB;
var
  sUser: String;
begin
  sUser := GetActiveUsername;
  if (sUser = '') or SameText(sUser, 'User') then Exit;

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text :=
        'UPDATE tblUsers SET CurrentBalance = :Bal, InitialBalance = :InitBal WHERE Username = :User';
      frmLogin.FDQuery1.ParamByName('Bal').AsString := FloatToStrF(rBaseCurrentBalanceZAR, ffFixed, 8, 2);
      frmLogin.FDQuery1.ParamByName('InitBal').AsString := FloatToStrF(rBaseInitialBalanceZAR, ffFixed, 8, 2);
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.ExecSQL;
    except
      on E: Exception do ;
    end;
  end;
end;

procedure TfrmPlanIT.CommitPendingExpensesToDB;
var
  I: Integer;
  sUser: String;
begin
  if iPendingCount = 0 then Exit;

  sUser := GetActiveUsername;
  if (sUser = '') or SameText(sUser, 'User') then Exit;

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      // loops through the temporary pending list and saves each expense entry safely to the database table
      for I := 1 to iPendingCount do
      begin
        frmLogin.FDQuery1.Close;
        frmLogin.FDQuery1.SQL.Text :=
          'INSERT INTO tblExpenses (Username, Category, Amount, ExpenseDate) VALUES (:User, :Cat, :Amt, :ExpDate)';
        frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
        frmLogin.FDQuery1.ParamByName('Cat').AsString := arrPendingCategories[I];
        frmLogin.FDQuery1.ParamByName('Amt').AsFloat := arrPendingAmounts[I];
        frmLogin.FDQuery1.ParamByName('ExpDate').AsString := arrPendingDates[I];
        frmLogin.FDQuery1.ExecSQL;
      end;
      ClearPendingExpenses;
    except
      on E: Exception do
        ShowMessage('Failed to commit pending expenses to database: ' + E.Message);
    end;
  end;
end;

procedure TfrmPlanIT.LoadUserStatsFromDB;
var
  sUser, sCat, sBalText, sInitText, sHighestEverCat, sMostFrequentCat: String;
  rAmt, rBal, rInit, rHighestEverAmount: Real;
  I, iFoundIndex, iCode, iMaxFreqIndex, iMaxCount: Integer;
begin
  sUser := GetActiveUsername;
  if (sUser = '') or SameText(sUser, 'User') then Exit;

  ClearCategoryArrays;

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      // fetches user balance records from the database and converts commas to dots for safety
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text := 'SELECT CurrentBalance, InitialBalance FROM tblUsers WHERE Username = :User';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.Open;

      if not frmLogin.FDQuery1.IsEmpty then
      begin
        sBalText := StringReplace(Trim(frmLogin.FDQuery1.FieldByName('CurrentBalance').AsString), ',', '.', [rfReplaceAll]);
        Val(sBalText, rBal, iCode);
        if iCode = 0 then rBaseCurrentBalanceZAR := rBal;

        sInitText := StringReplace(Trim(frmLogin.FDQuery1.FieldByName('InitialBalance').AsString), ',', '.', [rfReplaceAll]);
        Val(sInitText, rInit, iCode);
        if iCode = 0 then rBaseInitialBalanceZAR := rInit;

        RecalculateForCurrency;
      end;

      // loops through all recorded expenses to calculate category totals and counts parallel arrays
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text := 'SELECT Category, Amount FROM tblExpenses WHERE Username = :User';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.Open;

      while not frmLogin.FDQuery1.Eof do
      begin
        sCat := Trim(frmLogin.FDQuery1.FieldByName('Category').AsString);
        rAmt := frmLogin.FDQuery1.FieldByName('Amount').AsFloat;
        rTotalExpenses := rTotalExpenses + rAmt;

        iFoundIndex := 0;
        for I := 1 to iCategoryCount do
        begin
          if SameText(arrCategories[I], sCat) then
          begin
            iFoundIndex := I;
            Break;
          end;
        end;

        if iFoundIndex > 0 then
        begin
          arrCategoryTotals[iFoundIndex] := arrCategoryTotals[iFoundIndex] + rAmt;
          Inc(arrCategoryCounts[iFoundIndex]);
        end
        else if iCategoryCount < 50 then
        begin
          Inc(iCategoryCount);
          arrCategories[iCategoryCount] := sCat;
          arrCategoryTotals[iCategoryCount] := rAmt;
          arrCategoryCounts[iCategoryCount] := 1;
        end;

        frmLogin.FDQuery1.Next;
      end;

      // finds the single largest expense ever logged by sorting the query in descending order
      rHighestEverAmount := 0.0;
      sHighestEverCat := 'None';

      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text := 'SELECT Category, Amount FROM tblExpenses WHERE Username = :User ORDER BY Amount DESC';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.Open;

      if not frmLogin.FDQuery1.IsEmpty then
      begin
        sHighestEverCat := Trim(frmLogin.FDQuery1.FieldByName('Category').AsString);
        rHighestEverAmount := frmLogin.FDQuery1.FieldByName('Amount').AsFloat;
      end;

      if Assigned(lblHighestExpenseOut) then
      begin
        if rHighestEverAmount > 0 then
          lblHighestExpenseOut.Text := sHighestEverCat + ' (' + sCurrencySymbol + FloatToStrF(rHighestEverAmount, ffFixed, 8, 2) + ')'
        else
          lblHighestExpenseOut.Text := 'None';
      end;

      // loops through category counts to find the most frequently used category
      if iCategoryCount > 0 then
      begin
        iMaxFreqIndex := 1;
        iMaxCount := arrCategoryCounts[1];

        for I := 2 to iCategoryCount do
        begin
          if arrCategoryCounts[I] > iMaxCount then
          begin
            iMaxCount := arrCategoryCounts[I];
            iMaxFreqIndex := I;
          end;
        end;

        sMostFrequentCat := arrCategories[iMaxFreqIndex];
        if Assigned(lblMostFrequentExpenseOut) then
          lblMostFrequentExpenseOut.Text := sMostFrequentCat + ' (' + IntToStr(iMaxCount) + ' times)';
      end
      else
      begin
        if Assigned(lblMostFrequentExpenseOut) then
          lblMostFrequentExpenseOut.Text := 'None';
      end;

      UpdateLabels;
    except
      on E: Exception do ;
    end;
  end;
end;

procedure TfrmPlanIT.FormCreate(Sender: TObject);
begin
  Position := TFormPosition.ScreenCenter;
  TabControl1.ActiveTab := TabItem1;
  edtExpense.Text := '';
  cmbCategory.ItemIndex := -1;
  redOutput.Lines.Clear;
  DateEdit1.Date := Now;

  rCurrentBalance := 0.0;
  rInitialBalance := 0.0;
  rBaseCurrentBalanceZAR := 0.0;
  rBaseInitialBalanceZAR := 0.0;
  sCurrencySymbol := 'R';

  ClearCategoryArrays;
  ClearPendingExpenses;

  Randomize;
  PopulateFYIFacts;
  UpdateFYIFact;

  ComboBox1.ItemIndex := 0;
end;

procedure TfrmPlanIT.FormShow(Sender: TObject);
begin
  Image1.Opacity := 0;
  TAnimator.AnimateFloat(Image1, 'Opacity', 0.9, 2.0, TAnimationType.In, TInterpolationType.Linear);
  LoadUserStatsFromDB;
end;

procedure TfrmPlanIT.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveUserBalanceToDB;
  if Assigned(FYIFacts) then
    FreeAndNil(FYIFacts);
  Application.Terminate;
end;

procedure TfrmPlanIT.btnEditFundsClick(Sender: TObject);
begin
  SaveUserBalanceToDB;
  if Assigned(frmBalance) then
  begin
    Self.Hide;
    frmBalance.Show;
  end;
end;

procedure TfrmPlanIT.btnFundsClick(Sender: TObject);
begin
  btnEditFundsClick(Sender);
end;

procedure TfrmPlanIT.btnAddExpenseClick(Sender: TObject);
var
  rExpense, rRate: Real;
  iCode: Integer;
  sCategory, sCleanInput, sDateStr: String;
begin
  if rInitialBalance <= 0 then
  begin
    ShowMessage('Please set your starting balance first.');
    Exit;
  end;

  // validation to ensure the user actually picked a category from the combobox
  if cmbCategory.ItemIndex < 0 then
  begin
    ShowMessage('Please select an expense category.');
    if cmbCategory.CanFocus then
      cmbCategory.SetFocus;
    Exit;
  end;

  sCleanInput := Trim(edtExpense.Text);
  sCleanInput := StringReplace(sCleanInput, sCurrencySymbol, '', [rfReplaceAll, rfIgnoreCase]);
  sCleanInput := StringReplace(sCleanInput, ' ', '', [rfReplaceAll]);
  sCleanInput := StringReplace(sCleanInput, ',', '.', [rfReplaceAll]);

  Val(sCleanInput, rExpense, iCode);

  if (sCleanInput = '') or (iCode <> 0) or (rExpense <= 0) then
  begin
    ShowMessage('Please enter a valid expense amount.');
    if edtExpense.CanFocus then
      edtExpense.SetFocus;
    Exit;
  end;

  if rExpense > rCurrentBalance then
  begin
    ShowMessage('Expense exceeds available balance!');
    Exit;
  end;

  if iPendingCount >= 100 then
  begin
    ShowMessage('Pending expenses queue full. Please calculate your budget to process them.');
    Exit;
  end;

  sCategory := Trim(cmbCategory.Items[cmbCategory.ItemIndex]);

  sDateStr := FormatDateTime('yyyy/mm/dd', DateEdit1.Date);
  rRate := GetRateFromZAR(sCurrencySymbol);

  // updates local balances temporarily before committing to database
  rCurrentBalance := rCurrentBalance - rExpense;
  rBaseCurrentBalanceZAR := rBaseCurrentBalanceZAR - (rExpense / rRate);

  // adds expense into the local pending queue array instead of writing directly to database yet
  Inc(iPendingCount);
  arrPendingCategories[iPendingCount] := sCategory;
  arrPendingAmounts[iPendingCount] := rExpense;
  arrPendingDates[iPendingCount] := sDateStr;

  UpdateLabels;

  redOutput.Lines.Add(sCategory + ' - ' + sCurrencySymbol + FloatToStrF(rExpense, ffFixed, 8, 2) + ' (' + sDateStr + ') [Pending]');
  edtExpense.Text := '';
  cmbCategory.ItemIndex := -1;
end;

procedure TfrmPlanIT.btnCalculateBudgetClick(Sender: TObject);
var
  rBudgetUsed, rHighestEverAmount, rMaxCategoryAmount: Real;
  sAdvice, sHighestEverCat, sMostFrequentCat, sUser: String;
  I, iMaxIndex, iMaxFreqIndex, iMaxCount: Integer;
begin
  // commits any unsaved pending expenses and balances to the database table
  CommitPendingExpensesToDB;
  SaveUserBalanceToDB;

  // reloads stats from database to ensure everything is up to date
  LoadUserStatsFromDB;

  if iCategoryCount = 0 then
  begin
    ShowMessage('Please add at least one expense first.');
    Exit;
  end;

  sUser := GetActiveUsername;
  rHighestEverAmount := 0.0;
  sHighestEverCat := 'None';

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text := 'SELECT Category, Amount FROM tblExpenses WHERE Username = :User ORDER BY Amount DESC';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.Open;

      if not frmLogin.FDQuery1.IsEmpty then
      begin
        sHighestEverCat := Trim(frmLogin.FDQuery1.FieldByName('Category').AsString);
        rHighestEverAmount := frmLogin.FDQuery1.FieldByName('Amount').AsFloat;
      end;
    except
      on E: Exception do ;
    end;
  end;

  iMaxIndex := 1;
  rMaxCategoryAmount := arrCategoryTotals[1];
  iMaxFreqIndex := 1;
  iMaxCount := arrCategoryCounts[1];

  for I := 2 to iCategoryCount do
  begin
    if arrCategoryTotals[I] > rMaxCategoryAmount then
    begin
      rMaxCategoryAmount := arrCategoryTotals[I];
      iMaxIndex := I;
    end;

    if arrCategoryCounts[I] > iMaxCount then
    begin
      iMaxCount := arrCategoryCounts[I];
      iMaxFreqIndex := I;
    end;
  end;

  sMostFrequentCat := arrCategories[iMaxFreqIndex];

  if Assigned(lblHighestExpenseOut) then
  begin
    if rHighestEverAmount > 0 then
      lblHighestExpenseOut.Text := sHighestEverCat + ' (' + sCurrencySymbol + FloatToStrF(rHighestEverAmount, ffFixed, 8, 2) + ')'
    else
      lblHighestExpenseOut.Text := 'None';
  end;

  if Assigned(lblMostFrequentExpenseOut) then
  begin
    if iMaxCount > 0 then
      lblMostFrequentExpenseOut.Text := sMostFrequentCat + ' (' + IntToStr(iMaxCount) + ' times)'
    else
      lblMostFrequentExpenseOut.Text := 'None';
  end;

  if rInitialBalance > 0 then
    rBudgetUsed := (rTotalExpenses / rInitialBalance) * 100
  else
    rBudgetUsed := 0;

  if rBudgetUsed < 50 then
    sAdvice := 'Great job! You have used less than half of your budget.'
  else if rBudgetUsed <= 100 then
    sAdvice := 'You have remaining funds! Watch your non-essential spending.'
  else
    sAdvice := 'Warning: You have overspent your budget!';

  redOutput.Lines.Clear;
  redOutput.Lines.Add('=== PLANIT BUDGET SUMMARY ===');
  redOutput.Lines.Add('Starting Balance:          ' + sCurrencySymbol + FloatToStrF(rInitialBalance, ffFixed, 8, 2));
  redOutput.Lines.Add('Total Expenses:            ' + sCurrencySymbol + FloatToStrF(rTotalExpenses, ffFixed, 8, 2));
  redOutput.Lines.Add('Current Balance:           ' + sCurrencySymbol + FloatToStrF(rCurrentBalance, ffFixed, 8, 2));
  redOutput.Lines.Add('Highest Expense Ever:      ' + sHighestEverCat + ' (' + sCurrencySymbol + FloatToStrF(rHighestEverAmount, ffFixed, 8, 2) + ')');
  redOutput.Lines.Add('Most Frequent Category:    ' + sMostFrequentCat + ' (' + IntToStr(iMaxCount) + ' entries)');
  redOutput.Lines.Add('Budget Spent:              ' + FloatToStrF(rBudgetUsed, ffFixed, 8, 1) + '%');
  redOutput.Lines.Add('----------------------------------------');
  redOutput.Lines.Add('Advice: ' + sAdvice);
end;

procedure TfrmPlanIT.btnCalculateGoalClick(Sender: TObject);
var
  rGoalAmount, rMonthlyDeposit, rMonthsNeeded, rYearsNeeded: Real;
  sCleanGoal, sCleanDeposit: String;
  iCodeGoal, iCodeDeposit: Integer;
begin
  SaveUserBalanceToDB;

  sCleanGoal := Trim(StringReplace(Edit1.Text, sCurrencySymbol, '', [rfReplaceAll, rfIgnoreCase]));
  sCleanGoal := StringReplace(sCleanGoal, ',', '.', [rfReplaceAll]);
  Val(sCleanGoal, rGoalAmount, iCodeGoal);

  if (sCleanGoal = '') or (iCodeGoal <> 0) or (rGoalAmount <= 0) then
  begin
    ShowMessage('Please enter a valid savings goal amount.');
    Exit;
  end;

  sCleanDeposit := Trim(StringReplace(Edit2.Text, sCurrencySymbol, '', [rfReplaceAll, rfIgnoreCase]));
  sCleanDeposit := StringReplace(sCleanDeposit, ',', '.', [rfReplaceAll]);
  Val(sCleanDeposit, rMonthlyDeposit, iCodeDeposit);

  if (sCleanDeposit = '') or (iCodeDeposit <> 0) or (rMonthlyDeposit <= 0) then
  begin
    ShowMessage('Please enter a valid monthly deposit amount.');
    Exit;
  end;

  rMonthsNeeded := rGoalAmount / rMonthlyDeposit;
  rYearsNeeded := rMonthsNeeded / 12;

  lblGoalResult.WordWrap := True;

  if rMonthlyDeposit >= rGoalAmount then
    lblGoalResult.Text := 'Goal achieved immediately with 1 deposit!'
  else if rYearsNeeded > 50 then
    lblGoalResult.Text := 'Target takes ' + FloatToStrF(rYearsNeeded, ffFixed, 8, 0) + ' years. Try increasing your monthly deposit!'
  else
    lblGoalResult.Text := 'Goal reached in ' + FloatToStrF(rYearsNeeded, ffFixed, 8, 1) +
      ' years (' + FloatToStrF(rMonthsNeeded, ffFixed, 8, 0) + ' months)!';
end;

procedure TfrmPlanIT.btnCalculateInterestClick(Sender: TObject);
var
  rPrincipal, rRate, rYears, rTotalAmount, rInterestEarned: Real;
  iCode: Integer;
  sCleanInput, sRateText, sTimeText, sAssessment: String;
begin
  SaveUserBalanceToDB;

  sCleanInput := Trim(StringReplace(edtDepositAmount.Text, sCurrencySymbol, '', [rfReplaceAll, rfIgnoreCase]));
  sCleanInput := StringReplace(sCleanInput, ',', '.', [rfReplaceAll]);
  Val(sCleanInput, rPrincipal, iCode);

  if (sCleanInput = '') or (iCode <> 0) or (rPrincipal <= 0) then
  begin
    ShowMessage('Please enter a valid deposit amount.');
    Exit;
  end;

  if cmbTime.ItemIndex < 0 then
  begin
    ShowMessage('Please select a time duration.');
    Exit;
  end;

  sTimeText := cmbTime.Items[cmbTime.ItemIndex];

  if Pos('1 Month', sTimeText) > 0 then rYears := 1.0 / 12.0
  else if Pos('3 Months', sTimeText) > 0 then rYears := 3.0 / 12.0
  else if Pos('6 Months', sTimeText) > 0 then rYears := 6.0 / 12.0
  else if Pos('1 Year', sTimeText) > 0 then rYears := 1.0
  else if Pos('2 Years', sTimeText) > 0 then rYears := 2.0
  else if Pos('3 Years', sTimeText) > 0 then rYears := 3.0
  else if Pos('5 Years', sTimeText) > 0 then rYears := 5.0
  else if Pos('10 Years', sTimeText) > 0 then rYears := 10.0
  else rYears := 1.0;

  sRateText := Trim(StringReplace(cmbRate.Text, '%', '', [rfReplaceAll]));
  sRateText := StringReplace(sRateText, ',', '.', [rfReplaceAll]);
  Val(sRateText, rRate, iCode);

  if (iCode <> 0) or (rRate <= 0) then
  begin
    ShowMessage('Please select or enter a valid interest rate.');
    Exit;
  end;

  // compound interest formula calculation using Power function
  rTotalAmount := rPrincipal * Power(1.0 + (rRate / 100.0), rYears);
  rInterestEarned := rTotalAmount - rPrincipal;

  if rInterestEarned >= (rPrincipal * 0.50) then
    sAssessment := 'Excellent investment return!'
  else if rInterestEarned >= (rPrincipal * 0.20) then
    sAssessment := 'Good steady growth over time.'
  else
    sAssessment := 'Modest return. Consider longer durations.';

  memIntOutput.Lines.Clear;
  memIntOutput.Lines.Add('=== INTEREST CALCULATOR RESULTS ===');
  memIntOutput.Lines.Add('Initial Deposit:        ' + sCurrencySymbol + FloatToStrF(rPrincipal, ffFixed, 8, 2));
  memIntOutput.Lines.Add('Time Duration:          ' + sTimeText);
  memIntOutput.Lines.Add('Interest Rate:          ' + FloatToStrF(rRate, ffFixed, 8, 1) + '% p.a.');
  memIntOutput.Lines.Add('----------------------------------------');
  memIntOutput.Lines.Add('Interest Earned:        ' + sCurrencySymbol + FloatToStrF(rInterestEarned, ffFixed, 8, 2));
  memIntOutput.Lines.Add('Total Projected Value: ' + sCurrencySymbol + FloatToStrF(rTotalAmount, ffFixed, 8, 2));
  memIntOutput.Lines.Add('----------------------------------------');
  memIntOutput.Lines.Add('Assessment: ' + sAssessment);
end;

procedure TfrmPlanIT.btnInterestResetClick(Sender: TObject);
begin
  edtDepositAmount.Text := '';
  cmbTime.ItemIndex := -1;
  cmbRate.Text := '';
  cmbRate.ItemIndex := -1;
  memIntOutput.Lines.Clear;
end;

procedure TfrmPlanIT.btnResetGoalResetClick(Sender: TObject);
begin
  Edit1.Text := '';
  Edit2.Text := '';
  lblGoalResult.Text := 'It will take you: ';
end;

procedure TfrmPlanIT.btnHistoryClick(Sender: TObject);
var
  sUser: String;
begin
  SaveUserBalanceToDB;
  sUser := GetActiveUsername;

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    // queries all historical transaction records for the active user sorted by date descending
    frmLogin.FDQuery1.Close;
    frmLogin.FDQuery1.SQL.Text := 'SELECT Category, Amount, ExpenseDate FROM tblExpenses WHERE Username = :User ORDER BY ExpenseDate DESC';
    frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
    frmLogin.FDQuery1.Open;

    if Assigned(frmHistory) then
    begin
      frmHistory.rchHistory.Lines.Clear;
      frmHistory.rchHistory.Lines.Add('=== TRANSACTION HISTORY FOR ' + UpperCase(sUser) + ' ===');

      while not frmLogin.FDQuery1.Eof do
      begin
        frmHistory.rchHistory.Lines.Add(
          frmLogin.FDQuery1.FieldByName('ExpenseDate').AsString + ' | ' +
          frmLogin.FDQuery1.FieldByName('Category').AsString + ' | ' +
          sCurrencySymbol + FloatToStrF(frmLogin.FDQuery1.FieldByName('Amount').AsFloat, ffFixed, 8, 2)
        );
        frmLogin.FDQuery1.Next;
      end;

      frmHistory.Show;
      Self.Hide;
    end;
  end;
end;

procedure TfrmPlanIT.btnExportClick(Sender: TObject);
var
  SL: TStringList;
  sUser, sCurrentDate, sFullReportText: String;
  I: Integer;
begin
  SaveUserBalanceToDB;

  if redOutput.Lines.Count = 0 then
  begin
    ShowMessage('Calculate a budget before saving the report.');
    Exit;
  end;

  sUser := GetActiveUsername;
  sCurrentDate := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  SL := TStringList.Create;
  try
    SL.Add('===================================================');
    SL.Add(' Monthly Budget Report - ' + sCurrentDate + ' (' + sUser + ')');
    SL.Add('===================================================');
    SL.Add('');

    SL.Add('--- EXPENSE CATEGORIES BREAKDOWN ---');
    for I := 1 to iCategoryCount do
    begin
      SL.Add('  * ' + arrCategories[I] + ': ' + sCurrencySymbol + FloatToStrF(arrCategoryTotals[I], ffFixed, 8, 2));
    end;
    SL.Add('');

    SL.Add('--- SUMMARY & ANALYSIS ---');
    SL.Add(redOutput.Lines.Text);

    sFullReportText := SL.Text;
  finally
    SL.Free;
  end;

  if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
  begin
    try
      // saves the generated budget report directly into the database tblReports table
      frmLogin.FDQuery1.Close;
      frmLogin.FDQuery1.SQL.Text :=
        'INSERT INTO tblReports (Username, ReportDate, SummaryText) VALUES (:User, :RDate, :SText)';
      frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
      frmLogin.FDQuery1.ParamByName('RDate').AsString := sCurrentDate;
      frmLogin.FDQuery1.ParamByName('SText').AsString := sFullReportText;
      frmLogin.FDQuery1.ExecSQL;

      ShowMessage('Report successfully saved to the database!');
    except
      on E: Exception do
        ShowMessage('Failed to save report to database: ' + E.Message);
    end;
  end;
end;

procedure TfrmPlanIT.btnSaveClick(Sender: TObject);
begin
  if rBaseCurrentBalanceZAR = 0 then
    rBaseCurrentBalanceZAR := rCurrentBalance;
  if rBaseInitialBalanceZAR = 0 then
    rBaseInitialBalanceZAR := rInitialBalance;

  case ComboBox1.ItemIndex of
    0: sCurrencySymbol := 'R';
    1: sCurrencySymbol := '£';
    2: sCurrencySymbol := '$';
    3: sCurrencySymbol := '€';
    4: sCurrencySymbol := '¥';
  end;

  RecalculateForCurrency;
  UpdateLabels;
  SaveUserBalanceToDB;

  ShowMessage('Currency settings updated!');
  TabControl1.ActiveTab := TabItem1;
end;

procedure TfrmPlanIT.btnReloadFactClick(Sender: TObject);
begin
  UpdateFYIFact;
end;

procedure TfrmPlanIT.btnResetBudgetClick(Sender: TObject);
begin
  SaveUserBalanceToDB;
  ClearPendingExpenses;
  edtExpense.Text := '';
  cmbCategory.ItemIndex := -1;
  redOutput.Lines.Clear;
end;

procedure TfrmPlanIT.btnDeleteAccountClick(Sender: TObject);
var
  sUser: String;
begin
  sUser := GetActiveUsername;

  if (sUser = '') or SameText(sUser, 'User') then
  begin
    ShowMessage('No active user account found to delete.');
    Exit;
  end;

  if MessageDlg('Are you sure you want to permanently delete the account "' + sUser + '"? This action cannot be undone.',
      TMsgDlgType.mtWarning, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes then
  begin
    if Assigned(frmLogin) and frmLogin.FDConnection1.Connected then
    begin
      try
        // clears all user records from expenses, reports, and user tables when deleting account
        frmLogin.FDQuery1.Close;
        frmLogin.FDQuery1.SQL.Text := 'DELETE FROM tblExpenses WHERE Username = :User';
        frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
        frmLogin.FDQuery1.ExecSQL;

        frmLogin.FDQuery1.Close;
        frmLogin.FDQuery1.SQL.Text := 'DELETE FROM tblReports WHERE Username = :User';
        frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
        frmLogin.FDQuery1.ExecSQL;

        frmLogin.FDQuery1.Close;
        frmLogin.FDQuery1.SQL.Text := 'DELETE FROM tblUsers WHERE Username = :User';
        frmLogin.FDQuery1.ParamByName('User').AsString := sUser;
        frmLogin.FDQuery1.ExecSQL;
      except
        on E: Exception do ;
      end;
    end;

    ShowMessage('Account "' + sUser + '" has been deleted successfully.');

    ClearCategoryArrays;
    ClearPendingExpenses;
    rCurrentBalance := 0.0;
    rInitialBalance := 0.0;
    rBaseCurrentBalanceZAR := 0.0;
    rBaseInitialBalanceZAR := 0.0;

    Self.Hide;
    if Assigned(frmLogin) then
    begin
      frmLogin.edtUser.Text := '';
      frmLogin.edtPassword.Text := '';
      frmLogin.Show;
    end;
  end;
end;

procedure TfrmPlanIT.btnGoBackClick(Sender: TObject);
begin
  SaveUserBalanceToDB;
  ClearPendingExpenses;
  edtExpense.Text := '';
  cmbCategory.ItemIndex := -1;
  redOutput.Lines.Clear;

  Self.Hide;
  if Assigned(frmLogin) then
  begin
    frmLogin.edtUser.Text := '';
    frmLogin.edtPassword.Text := '';
    frmLogin.Show;
    frmLogin.edtUser.SetFocus;
  end;
end;

end.
