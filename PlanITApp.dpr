program PlanITApp;

uses
  System.StartupCopy,
  FMX.Forms,
  SignUp in 'SignUp.pas' {frmSignUp},
  PlanIT in 'PlanIT.pas' {frmPlanIT},
  History in 'History.pas' {frmHistory},
  Balance in 'Balance.pas' {frmBalance},
  Login in 'Login.pas' {frmLogin};

{$R *.res}

begin
  Application.Initialize;
  // First form created is the main startup window
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmSignUp, frmSignUp);
  Application.CreateForm(TfrmPlanIT, frmPlanIT);
  Application.CreateForm(TfrmHistory, frmHistory);
  Application.CreateForm(TfrmBalance, frmBalance);
  Application.Run;
end.
