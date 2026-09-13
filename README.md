# PlanIT V1.0 - Personal Finance & Budgeting Desktop Application

PlanIT is a desktop application designed to streamline personal financial management, expense tracking, and long-term budget forecasting. Whether you are looking to manage daily spending, build a savings fund, or project future investment returns, PlanIT delivers essential money management tools in one centralized desktop environment.

---


### Installation Instructions:
1. Click the download link above to download **PlanITApp.zip**.
2. Extract all contents of the `.zip` file into a single directory on your computer.
3. Ensure the **Database** subfolder (containing `PlanIT_Database.accdb`) remains in the exact same directory alongside `PlanITApp.exe`.
4. Double-click **PlanITApp.exe** to launch the application immediately—no IDE, Delphi compiler, or local database configuration required!

---

## ✨ Key Features & Functionality

* **Expense & Income Logging:** Record transaction items by category, view real-time account balances, and track running spending totals.
* **Smart Analytics Dashboard:** Identify top spending categories and track high-value transaction metrics to help optimize personal budgeting.
* **Savings Goal Planner:** Calculate timeline targets to reach specific savings milestones and evaluate whether current monthly deposits meet deadline expectations.
* **Compound Interest Calculator:** Forecast long-term growth across flexible time horizons and interest rates to maximize investment returns.
* **Multi-Currency Conversion:** Convert foreign transaction values directly into South African Rand (ZAR) base values.
* **Backend Database Storage:** Persist transaction logs, history entries, and financial audit records using an integrated Microsoft Access database backend.
* **Financial Educational Insights:** View money-management principles and practical saving tips upon application startup.

---

## 🛠️ Technical Specifications

| Component | Specification |
| :--- | :--- |
| **Development Environment** | Embarcadero Delphi |
| **UI Framework** | FireMonkey (FMX) |
| **Programming Language** | Object Pascal |
| **Backend Database** | Microsoft Access (`.accdb`) |
| **Target OS** | Windows 10 / 11 (64-bit) |

---

## 📁 Repository & Project Structure

```text
PlanIT/
├── Database/
│   └── PlanIT_Database.accdb     # Backend MS Access database file
├── Source/                        # Delphi source code files (.pas, .fmx)
├── PlanITApp.exe                 # Compiled Windows application executable
└── README.md                      # Project documentation and download guide
