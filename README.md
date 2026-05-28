# 🏦 Nova Bank — Credit Risk Analytics & Early Warning System

> End-to-end credit risk analysis platform combining machine learning, SQL-based data engineering, and Power BI dashboards for a multi-country loan portfolio.

---

## 📌 Project Overview

Nova Bank faces a portfolio-wide default rate of **~21.8%** — significantly above the industry benchmark of 3–8% for consumer lending. This project builds a full data pipeline and predictive system to identify high-risk borrowers early, segment the loan portfolio, and support data-driven credit decisions across **US, UK, and Canada**.

---

## 🗂️ Repository Structure

```
nova-bank-credit-risk/
│
├── Nova_Bank_Credit_Risk.ipynb       # Main analysis notebook (EDA + ML models)
│
├── sql/
│   ├── dbo_vw_loan_enriched_View.sql        # Core enriched view (base layer)
│   ├── dbo_vw_summary_overview_View.sql     # KPI overview
│   ├── dbo_vw_summary_loan_risk_View.sql    # Loan grade & intent analysis
│   ├── dbo_vw_summary_borrower_View.sql     # Borrower segmentation
│   ├── dbo_vw_summary_financial_View.sql    # DTI, LTI, Credit Utilization
│   ├── dbo_vw_summary_country_View.sql      # Country comparison
│   ├── dbo_vw_summary_early_warning_View.sql# Early warning signals
│   ├── dbo_vw_geo_map_View.sql              # Geographic map data
│   ├── dbo_vw_scatter_data_View.sql         # Scatter plot data (loan-level)
│   └── SQLQuery21.sql                       # Validation queries
│
└── README.md
```

---

## 📊 Dataset

| Attribute | Detail |
|-----------|--------|
| Records | 32,581 loan applications |
| Features | 29 variables |
| Markets | United States, United Kingdom, Canada |
| Target | `loan_status` — 1 = Default, 0 = Non-default |

**Feature groups:** demographic (age, gender, education), financial (income, DTI, credit utilization), credit history (delinquencies, credit history length), loan characteristics (grade A–G, intent, term).

---

## ⚙️ Tech Stack

| Layer | Tools |
|-------|-------|
| Data Processing | Python, Pandas, NumPy |
| Machine Learning | Scikit-learn, Gradient Boosting, Random Forest, Logistic Regression, SMOTE |
| Data Engineering | SQL Server T-SQL, 10+ analytical views |
| Visualization | Matplotlib, Seaborn, Power BI |
| Imbalance Handling | SMOTE (imbalanced-learn) |

---

## 🔬 Methodology

**Phase 1 — Data Preprocessing**
- Imputed `loan_int_rate` using grade-conditional median; `person_emp_length` via global median.
- Detected and capped outliers via IQR method (`person_emp_length` capped at 40 years; removed `person_age > 100`).
- Engineered new features: `age_group`, `income_group`, `risk_score`, `risk_segment`.

**Phase 2 — Exploratory Data Analysis**
- Univariate and multivariate analysis across all borrower and loan dimensions.
- Chi-square test (categorical) and Mann-Whitney U test (numerical) for statistical significance.

**Phase 3 — Machine Learning**
- 80/20 stratified train-test split.
- SMOTE applied to address class imbalance.
- Trained and compared: Logistic Regression (baseline), Random Forest, Gradient Boosting.
- Evaluated via 5-fold cross-validation: ROC-AUC, Recall, F1-Score, AUC-PR.

**Phase 4 — Segmentation & Threshold Analysis**
- Composite risk score → 3-tier segmentation: **Safe / Medium / High Risk**.
- Threshold sensitivity analysis to optimize decision boundary beyond default 0.5.

---

## 🤖 Model Results

| Model | ROC-AUC | Recall | F1-Score | AUC-PR |
|-------|---------|--------|----------|--------|
| Logistic Regression | baseline | — | — | — |
| Random Forest | competitive | — | — | — |
| **Gradient Boosting** | **> 0.90** | highest | highest | highest |

> ✅ **Gradient Boosting** selected as the production model. Recommended for quarterly retraining to track behavioral drift.

---

## 🏗️ Data Engineering — SQL View Architecture

Built on SQL Server (`NovaBank` database), the analytical layer consists of 9 views:

```
dbo.vw_loan_enriched          ← Master enriched view (10+ derived metrics)
        │
        ├── vw_summary_overview        ← Top-level KPIs + grade/intent/country breakdown
        ├── vw_summary_loan_risk       ← Grade × Intent matrix, term, interest rate groups
        ├── vw_summary_borrower        ← Age, income, housing, education, gender, marital status
        ├── vw_summary_financial       ← DTI, Credit Utilization, Loan-to-Income vs default
        ├── vw_summary_country         ← US / UK / Canada cross-dimensional comparison
        ├── vw_summary_early_warning   ← Red Zone flag, delinquency groups, warning score bands
        ├── vw_geo_map                 ← City/state/country aggregation for map visuals
        └── vw_scatter_data            ← Loan-level data for scatter plots (optimized columns)
```

Key derived metrics in `vw_loan_enriched`:
- `early_warning_score` — composite signal (0 = no risk → 7+ = critical)
- `is_red_zone` — binary flag for immediate intervention
- `estimated_loss`, `estimated_interest` — financial impact quantification
- `debt_to_income_ratio`, `credit_utilization_ratio`, `loan_to_income_ratio`
- `risk_category`, `grade_risk_label`, `delinquency_group`

---

## 🚨 Early Warning System

Borrowers are scored across 4 risk bands:

| Band | Score | Label |
|------|-------|-------|
| 0 | 0 | No risk |
| 1 | 1–3 | Caution |
| 2 | 4–6 | Danger |
| 3 | 7+ | Critical |

`is_red_zone = 1` triggers immediate escalation. Integrated directly into Power BI dashboards for real-time officer review.

---

## 📈 Key Findings

- Default rate of **~21.8%** — 3–7× above consumer lending industry standard.
- Strongest default predictors: **loan grade, loan-to-income ratio, DTI, interest rate, past delinquencies, default history**.
- Country (US/UK/CA) has **no significant impact** on default — borrower financials matter more than geography.
- High-risk segments: **Grade E–G**, **VENTURE loans**, **income < $30K**, **unemployment**, **2+ past delinquencies**.
- A single unified scoring model is viable across all 3 markets.

---

## 💡 Recommendations

**Credit Policy**
- Auto-reject if `loan_percent_income > 0.45` or `DTI > 0.60`.
- Mandatory collateral for Grade E–G loans.
- Enhanced review for borrowers under 25 or with `past_delinquencies ≥ 2`.

**Portfolio Management**
- Integrate composite risk score into real-time approval dashboard.
- Tailored strategy per segment: fast-track approval (Safe), conditional approval (Medium), reject/guarantee required (High Risk).

**Model & System**
- Deploy Gradient Boosting as the primary scoring engine; retrain quarterly.
- Adjust decision threshold via Cost-Benefit Analysis (cost of missed default vs. cost of rejected good borrower).
- Future: integrate transaction behavioral data + Explainable AI (SHAP values).

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/your-username/nova-bank-credit-risk.git
cd nova-bank-credit-risk

# Install dependencies
pip install -r requirements.txt

# Run the notebook
jupyter notebook Nova_Bank_Credit_Risk.ipynb
```

**SQL Setup:** Execute view scripts in order — `vw_loan_enriched` first, then all `vw_summary_*` views against your `NovaBank` SQL Server database.

---

## 📦 Requirements

```
pandas
numpy
matplotlib
seaborn
scikit-learn
imbalanced-learn
openpyxl
jupyter
```

---

## 👤 Author

**PhamNgocTheKieu**  
Data Analytics | Credit Risk | Machine Learning

---

*This project is for analytical and educational purposes.*
