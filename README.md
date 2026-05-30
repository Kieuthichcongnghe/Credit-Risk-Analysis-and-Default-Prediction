#  NovaBank Credit Risk Analytics

> **Ứng dụng học máy và phân tích danh mục tín dụng trong quản lý rủi ro cho vay tiêu dùng**
>
> *Tác giả: PhamNgocTheKieu*

---

##  Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Bộ dữ liệu](#2-bộ-dữ-liệu)
3. [Kiến trúc hệ thống & SQL Pipeline](#3-kiến-trúc-hệ-thống--sql-pipeline)
4. [Kết quả phân tích EDA](#4-kết-quả-phân-tích-eda)
5. [Kết quả mô hình dự đoán](#5-kết-quả-mô-hình-dự-đoán)
6. [Giám sát danh mục cho vay](#6-giám-sát-danh-mục-cho-vay)
7. [Thực nghiệm A/B Test](#7-thực-nghiệm-ab-test)
8. [Phân khúc rủi ro người vay](#8-phân-khúc-rủi-ro-người-vay)
9. [Khuyến nghị chính sách](#9-khuyến-nghị-chính-sách)
10. [Cấu trúc dự án](#10-cấu-trúc-dự-án)
11. [Công nghệ sử dụng](#11-công-nghệ-sử-dụng)

---

## 1. Tổng quan dự án

### Bối cảnh & Vấn đề

Tại **Nova Bank**, tỷ lệ nợ quá hạn lên đến **~21,8%** — cao gấp **3–7 lần** so với chuẩn ngành cho vay tiêu dùng thông thường (3–8%). Thực trạng này đặt ra yêu cầu cấp thiết phải xây dựng một framework phân tích rủi ro tín dụng toàn diện, bao gồm khả năng phát hiện sớm, dự báo và giám sát liên tục.

### Mục tiêu nghiên cứu

Dự án được xây dựng theo **4 mục tiêu cốt lõi** phản ánh workflow thực tế của một Credit Risk Analyst trong môi trường Fintech:

| Mục tiêu | Nội dung |
|----------|----------|
| **1 – EDA** | Khám phá phân phối, cấu trúc dữ liệu; xác định các nhân tố nhân khẩu học, tài chính và lịch sử tín dụng ảnh hưởng đến xác suất nợ quá hạn |
| **2 – Mô hình dự đoán** | Huấn luyện và so sánh 3 mô hình ML; giám sát độ lệch phân phối sau triển khai (PSI/CSI) |
| **3 – Giám sát danh mục** | Xây dựng DPD distribution, roll rate matrix, vintage curves — các công cụ cốt lõi trong Credit Risk Monitoring |
| **4 – Thực nghiệm & Khuyến nghị** | Thiết kế framework A/B test champion-challenger; đề xuất chiến lược phân khúc rủi ro |

---

## 2. Bộ dữ liệu

### Thông tin tổng quát

| Thuộc tính | Giá trị |
|------------|---------|
| **Tổng số hồ sơ** | 32.581 khoản vay cá nhân |
| **Số biến** | 29 biến gốc + ~25 biến phái sinh |
| **Phạm vi địa lý** | Mỹ (USA), Anh (UK), Canada |
| **Biến mục tiêu** | `loan_status` — 1 = Nợ quá hạn, 0 = Trả đúng hạn |
| **Tỷ lệ mất cân bằng** | 78,2% (Non-default) vs 21,8% (Default) |

### Cấu trúc biến

| Nhóm biến | Các biến chính |
|-----------|---------------|
| **Nhân khẩu học** | `person_age`, `gender`, `marital_status`, `education_level`, `country`, `state`, `city` |
| **Tài chính** | `person_income`, `loan_amnt`, `loan_int_rate`, `loan_percent_income`, `debt_to_income_ratio`, `credit_utilization_ratio` |
| **Lịch sử tín dụng** | `cb_person_cred_hist_length`, `cb_person_default_on_file`, `past_delinquencies`, `open_accounts` |
| **Đặc điểm khoản vay** | `loan_grade` (A–G), `loan_intent`, `loan_term_months`, `loan_to_income_ratio` |
| **Việc làm & Nhà ở** | `person_home_ownership`, `employment_type`, `person_emp_length` |

### Feature Engineering (vw_loan_enriched)

Từ 29 biến gốc, `vw_loan_enriched` sinh ra thêm các biến phái sinh phục vụ phân tích và dashboard:

- **Nhóm phân loại:** `age_group`, `income_group`, `loan_amount_group`, `interest_rate_group`, `dti_group`, `credit_util_group`, `lti_group`, `delinquency_group`, `cred_hist_group`
- **Nhãn rủi ro:** `grade_risk_label`, `risk_category`, `loan_status_label`
- **Early Warning Score (0–10 điểm):** Tổng hợp từ lịch sử nợ xấu, số lần delinquency, DTI, credit utilization → phân loại Red Zone / Normal
- **Tài chính ước tính:** `estimated_interest`, `estimated_loss`

---

## 3. Kiến trúc hệ thống & SQL Pipeline

### Sơ đồ các View SQL

```
Credit_Risk_Dataset (Bảng gốc)
          │
          ▼
  vw_loan_enriched  ◄─────────────────── VIEW TRUNG TÂM
  (Feature Engineering,                  (29 biến gốc + ~25 biến phái sinh)
   Risk Scoring, Grouping)
          │
    ┌─────┼──────────────────────────────┐
    │     │                              │
    ▼     ▼                              ▼
vw_summary_overview    vw_summary_borrower    vw_summary_loan_risk
(KPI tổng thể,         (Nhân khẩu học:        (Grade × Intent matrix,
 By Grade/Intent/      Tuổi, Thu nhập,        Lãi suất, Kỳ hạn,
 Country/Status)       Nhà ở, Học vấn,        Quy mô khoản vay)
                       Giới tính, Hôn nhân)

vw_summary_financial   vw_summary_early_warning   vw_summary_country
(DTI, Credit Util,     (Lịch sử nợ,               (So sánh USA/UK/Canada:
 LTI, By Risk Cat.)    Delinquency groups,         KPI, Grade, Intent,
                       Early Warning Score,        Employment type)
                       Red Zone summary)

vw_geo_map             vw_scatter_data
(Lat/Long aggregation  (Loan-level data cho
 cho Power BI map)     scatter plots)
```

### Danh sách Views

| View | Mục đích |
|------|---------|
| `vw_loan_enriched` | View trung tâm — feature engineering & risk scoring |
| `vw_summary_overview` | KPI tổng quan + phân bố default theo grade, intent, country |
| `vw_summary_borrower` | Phân tích người vay: tuổi, thu nhập, nhà ở, học vấn, việc làm, giới tính |
| `vw_summary_loan_risk` | Phân tích khoản vay: grade, intent, lãi suất, kỳ hạn, quy mô |
| `vw_summary_financial` | DTI, Credit Utilization, Loan-to-Income vs Default |
| `vw_summary_early_warning` | Phát hiện sớm rủi ro: lịch sử, delinquencies, Red Zone |
| `vw_summary_country` | So sánh US, UK, Canada theo nhiều chiều |
| `vw_geo_map` | Tổng hợp theo địa lý cho Power BI map visual |
| `vw_scatter_data` | Dữ liệu cấp độ khoản vay cho scatter plots |

---

## 4. Kết quả phân tích EDA

### 4.1 KPI tổng thể

| Chỉ số | Giá trị |
|--------|---------|
| Tổng số khoản vay | 32.581 |
| Tỷ lệ nợ quá hạn | **~21,8%** |
| Benchmark ngành | 3–8% |
| Mức độ vượt benchmark | **Gấp 3–7 lần** |

### 4.2 Các yếu tố rủi ro chính

**Tài chính (chênh lệch Default vs Non-Default):**

| Chỉ số | Không Default (TB) | Default (TB) | Chênh lệch |
|--------|--------------------|--------------|------------|
| Lãi suất (%) | ~10–11% | ~14–15% | +4 pp |
| Loan/Income | ~0,10 | ~0,22 | ×2,2 |
| DTI | ~0,35 | ~0,55 | +57% |
| Số tiền vay (USD) | ~7.500 | ~11.000 | +47% |

**Ngưỡng cảnh báo đỏ (Red Flags):**
- `Loan/Income > 0,30`
- `DTI > 0,50`
- `past_delinquencies ≥ 2`
- `loan_percent_income > 0,40`

### 4.3 Phân tích theo Loan Grade

| Grade | Mức rủi ro | Tỷ lệ Default |
|-------|-----------|---------------|
| A | Rất thấp | < 5% |
| B | Thấp | 5–10% |
| C | Trung bình | 10–20% |
| D | Cao | 20–35% |
| E | Rất cao | 35–55% |
| F–G | Cực cao | 55–80% |

**Insight:** Grade A–B là "nhóm vàng" của danh mục. Grade F–G có tỷ lệ default không thể bù đắp bằng lãi suất cao.

### 4.4 Phân tích theo Mục đích vay

| Mục đích | Mức rủi ro | Lý giải |
|----------|-----------|---------|
| VENTURE (Kinh doanh) | Cao nhất | Thu nhập từ kinh doanh không ổn định |
| EDUCATION (Giáo dục) | Cao | Thu nhập chưa có ngay |
| MEDICAL (Y tế) | Trung bình | Nhu cầu thiết yếu, có áp lực hoàn trả |
| HOMEIMPROVEMENT (Cải thiện nhà) | Thấp nhất | Tăng giá trị tài sản, động lực bảo vệ nhà |

**Tổ hợp rủi ro cao nhất:** `VENTURE × Grade F–G` → nên ngừng cấp hoặc yêu cầu tài sản bảo đảm bắt buộc.

### 4.5 Phân tích theo Nhân khẩu học

- **Nhóm tuổi:** Người vay 18–25 có tỷ lệ default cao nhất; nhóm 36–45 thấp nhất nhờ thu nhập ổn định
- **Nhà ở:** Người thuê nhà (RENT) rủi ro cao hơn người có nhà (MORTGAGE/OWN)
- **Việc làm:** Người thất nghiệp/bán thời gian là nhóm rủi ro cao rõ ràng
- **Quốc gia:** USA, UK, Canada có tỷ lệ tương đồng (~21–22%) → Rủi ro đến từ hồ sơ cá nhân, không phải yếu tố địa lý

### 4.6 Kiểm định thống kê

**Chi-square (biến phân loại):**
- `loan_grade` — Cramér's V cao nhất → phân biệt rủi ro mạnh nhất
- `cb_person_default_on_file` — biến đơn có sức mạnh dự báo cao nhất
- `employment_type` — phân biệt rõ ràng giữa các loại hình việc làm
- `country` — Cramér's V thấp → xác nhận quốc gia không phải yếu tố quyết định

**Mann-Whitney (biến số):**
- `loan_int_rate`, `loan_percent_income`, `debt_to_income_ratio`, `past_delinquencies` — tất cả có **p < 0,001** và chênh lệch lớn giữa hai nhóm

---

## 5. Kết quả mô hình dự đoán

### 5.1 Pipeline xử lý

```
Dữ liệu thô
    │
    ▼
Tiền xử lý (Impute missing values theo median by group)
    │
    ▼
Phát hiện & xử lý Outlier (IQR method, cap person_emp_length ≤ 40)
    │
    ▼
Feature Engineering (17 features: 12 numeric + 5 categorical)
    │
    ▼
Stratified Split (80% train / 20% test)
    │
    ▼
SMOTE (xử lý mất cân bằng lớp: ~78%/22% → 50%/50%)
    │
    ▼
Train 3 mô hình: Logistic Regression / Random Forest / Gradient Boosting
    │
    ▼
Đánh giá: ROC-AUC, AUC-PR, F1, Precision, Recall + Cross-validation (5-fold)
```

### 5.2 Hiệu suất các mô hình

| Mô hình | ROC-AUC | AUC-PR | F1-Score | Recall | Precision |
|---------|---------|--------|----------|--------|-----------|
| Logistic Regression | ~0,83 | ~0,65 | ~0,72 | ~0,74 | ~0,71 |
| Random Forest | ~0,88 | ~0,72 | ~0,77 | ~0,76 | ~0,78 |
| **Gradient Boosting** | **> 0,90** | **~0,78** | **~0,80** | **~0,79** | **~0,81** |

**→ Gradient Boosting là mô hình tốt nhất**, đạt ROC-AUC > 0,90 nhờ khả năng nắm bắt các quan hệ phi tuyến trong dữ liệu.

### 5.3 Top features quan trọng nhất (Random Forest Feature Importance)

1. `loan_int_rate` — Lãi suất khoản vay
2. `loan_percent_income` — Tỷ lệ khoản vay / Thu nhập
3. `debt_to_income_ratio` — DTI Ratio
4. `cb_person_default_on_file` — Lịch sử nợ xấu
5. `past_delinquencies` — Số lần nợ quá hạn quá khứ
6. `credit_utilization_ratio` — Tỷ lệ sử dụng tín dụng
7. `loan_grade` (encoded) — Xếp hạng khoản vay
8. `person_income` — Thu nhập
9. `loan_amnt` — Số tiền vay
10. `cb_person_cred_hist_length` — Độ dài lịch sử tín dụng

### 5.4 Ngưỡng quyết định tối ưu

Sử dụng ngưỡng mặc định 0,5 **không tối ưu** cho bài toán tín dụng. Do chi phí False Negative (bỏ sót nợ xấu) >> chi phí False Positive (từ chối oan):

- **Ngưỡng tối ưu F1:** ~0,40–0,45
- **Ngưỡng tăng Recall (bảo thủ):** ~0,30–0,35

```
Chi phí FN (bỏ lọt Default) = Mất vốn gốc + lãi + chi phí thu hồi
Chi phí FP (từ chối oan)    = Mất doanh thu lãi từ khách hàng tốt
→ FN cost >> FP cost → hạ ngưỡng để tăng Recall
```

---

## 6. Giám sát danh mục cho vay

### 6.1 DPD Distribution (Days Past Due)

| DPD Bucket | Màu cảnh báo | Ý nghĩa |
|------------|-------------|---------|
| Current (0) | 🟢 Xanh | Trả đúng hạn |
| DPD 1–29 | 🟡 Vàng nhạt | Trễ nhẹ — theo dõi |
| DPD 30–59 | 🟠 Cam | Delinquent — hành động sớm |
| DPD 60–89 | 🔴 Đỏ | Rủi ro cao — escalate |
| DPD 90–119 | 🔴 Đỏ đậm | Nghiêm trọng |
| DPD 120+ | ⚫ Nâu đen | Gần như mất vốn |

**Trigger cảnh báo:** DPD 30+ tăng > 2 điểm phần trăm so với tháng trước → cần rà soát chính sách ngay.

### 6.2 Roll Rate Matrix

| Chỉ số | Ý nghĩa | Hành động khi bất thường |
|--------|---------|-------------------------|
| **Cure Rate** (→ Current) | Tỷ lệ khách hàng tự hồi phục | Thấp < 30% → xem lại quy trình collection |
| **Roll-Forward Rate** | Tỷ lệ chuyển sang bucket xấu hơn | Tăng đột biến → điều chỉnh chính sách ngay |
| **Roll-Back Rate** | Tỷ lệ khách hàng cải thiện | Dõi hiệu quả thu hồi nợ |

### 6.3 Vintage Curve Analysis

Mỗi đường vintage đại diện cho một cohort (tháng giải ngân). Dự án xây dựng vintage curves cho **18 cohorts** (2022–01 đến 2023–06) theo dõi 24 tháng.

**Cách đọc:**
- Đường vintage dốc hơn các cohort trước → underwriting lax hơn hoặc macro environment xấu đi
- Cumulative default tại MOB 3 của cohort mới cao hơn cohort cũ cùng MOB → cảnh báo sớm chất lượng danh mục

### 6.4 PSI / CSI Monitoring

| Chỉ số | Đo gì | Ngưỡng hành động |
|--------|-------|-----------------|
| **PSI** (Population Stability Index) | Độ ổn định của score phân phối | < 0,10: Ổn định; 0,10–0,20: Theo dõi; > 0,20: Retrain |
| **CSI** (Characteristic Stability Index) | Độ ổn định của từng feature | Tương tự PSI |

**Workflow production:** Chạy tự động hàng tháng qua SQL pipeline (BigQuery/Airflow). PSI > 0,1 → điều tra nguyên nhân; PSI > 0,2 → kích hoạt quy trình tái huấn luyện.

---

## 7. Thực nghiệm A/B Test

### 7.1 Thiết kế Champion-Challenger

| Nhóm | Tỷ lệ phân bổ | Policy |
|------|--------------|--------|
| **Champion** (Control) | 80% | Approve nếu `model_score < 0,5` |
| **Challenger** (Treatment) | 20% | Approve nếu `model_score < 0,5` **VÀ** `DTI < 0,50` |

### 7.2 Kết quả thực nghiệm

| Metric | Champion | Challenger | Δ |
|--------|---------|-----------|---|
| Approval Rate | ~77% | ~65% | Challenger phê duyệt ít hơn ~12 pp |
| Default Rate (approved) | ~22% | ~15% | **Challenger giảm default ~7 pp** |

**Kiểm định thống kê (Z-test):** Chênh lệch default rate giữa hai nhóm có ý nghĩa thống kê (p < 0,05).

### 7.3 Framework đánh giá

```
Lợi ích ròng = (Default rate champion − Default rate challenger) × Giá trị vay TB × LGD
             − (Approval rate champion − Approval rate challenger) × Giá trị vay TB × Biên lãi ròng
```

**Lưu ý thực tiễn:** Cần ít nhất **4–8 tuần** thu thập dữ liệu và thêm **3 tháng** theo dõi để tính delinquency rate có ý nghĩa.

---

## 8. Phân khúc rủi ro người vay

### 8.1 Ba nhóm rủi ro

| Nhóm | Tỷ lệ Default | Đặc điểm điển hình |
|------|---------------|-------------------|
| 🟢 **An toàn** | 5–8% | Lãi suất ~9%, DTI < 0,30, không có nợ xấu |
| 🟡 **Trung bình** | ~20% | Lãi suất ~12%, DTI 0,30–0,50, một vài delinquency |
| 🔴 **Rủi ro cao** | 40–55% | Lãi suất ~16%, DTI > 0,50, có lịch sử nợ xấu |

### 8.2 Chiến lược theo nhóm

| Nhóm | Chiến lược |
|------|-----------|
| 🟢 An toàn | Pre-approve, lãi suất ưu đãi, tăng credit limit, upsell sản phẩm tài chính khác |
| 🟡 Trung bình | Approve có điều kiện: giảm limit 30%, monitor monthly, gửi reminder trước due date |
| 🔴 Rủi ro cao | Yêu cầu tài sản bảo đảm/người bảo lãnh, hoặc từ chối và offer chương trình tư vấn tài chính |

### 8.3 Bảng tóm tắt rủi ro tổng thể

| Chiều phân tích | Tỷ lệ Default | So với TB (21,8%) |
|----------------|---------------|------------------|
| Grade A–B | < 10% | ↓ Thấp |
| Grade E–G | > 50% | ↑↑ Rất cao |
| Thu nhập < 30K | ~28% | ↑ Cao |
| Thu nhập > 90K | ~14% | ↓ Thấp |
| Có lịch sử nợ xấu | ~35% | ↑↑ Rất cao |
| Không có nợ xấu | ~16% | ↓ Thấp |
| Người thất nghiệp | ~35%+ | ↑↑ Rất cao |
| Full-time employment | ~18% | ↓ Thấp |
| VENTURE intent | ~30% | ↑ Cao |
| HOMEIMPROVEMENT | ~13% | ↓ Thấp |
| DTI > 0,50 | ~35% | ↑↑ Rất cao |
| Loan/Income > 0,40 | ~38% | ↑↑ Rất cao |

---

## 9. Khuyến nghị chính sách

### 9.1 Chính sách phê duyệt tín dụng

**🔴 Hard Rules — Tự động từ chối:**
- `loan_percent_income > 0,45` **HOẶC** `DTI > 0,60`
- `loan_grade = F hoặc G` kết hợp `loan_intent = VENTURE`
- `past_delinquencies ≥ 3`
- Người thất nghiệp, không có thu nhập chứng minh

**🟡 Soft Rules — Phê duyệt có điều kiện:**
- `0,35 < loan_percent_income ≤ 0,45` → yêu cầu thêm tài liệu, giảm 30% hạn mức
- `past_delinquencies = 2` + `loan_percent_income > 0,30` → chuyển sang hàng đợi xét duyệt thủ công
- Người vay dưới 25 tuổi → yêu cầu người đồng bảo lãnh hoặc giảm hạn mức
- `loan_grade = E` → yêu cầu tài sản bảo đảm (collateral)

**🟢 Fast-Track Approval — Duyệt nhanh:**
- `loan_grade A hoặc B` + `DTI < 0,30` + không có nợ xấu lịch sử + toàn thời gian
- Lịch sử tín dụng ≥ 10 năm + không có `past_delinquencies`

### 9.2 Giám sát danh mục

- **Daily/Weekly:** DPD bucket distribution, Delinquency rate theo Grade/Intent/Vintage
- **Monthly:** Roll rate matrix, Vintage curve comparison, PSI/CSI monitoring
- **Trigger alert:** Roll-forward rate tăng > 20% so với tháng trước → hành động ngay

### 9.3 Roadmap phát triển mô hình

| Giai đoạn | Hành động |
|-----------|---------|
| **Ngắn hạn** | Tích hợp SHAP values để giải thích quyết định từng hồ sơ (yêu cầu tuân thủ quy định) |
| **Trung hạn** | Kết hợp dữ liệu hành vi giao dịch (transaction velocity, merchant category) — đặc biệt quan trọng trong BNPL |
| **Dài hạn** | Xây dựng Early Warning System (EWS) theo dõi người vay hiện hữu theo thời gian thực |

### 9.4 Các cải tiến kỹ thuật đề xuất

| Hạn chế hiện tại | Hướng cải thiện |
|-----------------|----------------|
| Dữ liệu tĩnh tại thời điểm vay | Bổ sung dữ liệu hành vi động (transaction velocity, merchant pattern) |
| Mô hình batch (train một lần) | Online learning / tái huấn luyện gia tăng mỗi tháng |
| Phân loại nhị phân (default/no default) | Đa lớp: Current / At-risk / Delinquent / Default |
| SMOTE xử lý mất cân bằng | Cost-sensitive learning hoặc Focal Loss |
| Ngưỡng cố định | Ngưỡng động điều chỉnh theo khẩu vị rủi ro từng quý |

---

## 10. Cấu trúc dự án

```
NovaBank_Credit_Risk/
│
├──  NovaBank_Credit_Risk.ipynb          # Notebook chính (EDA, Models, Monitoring, A/B Test)
│
├──  SQL Views/
│   ├── dbo_vw_loan_enriched_View.sql      # VIEW TRUNG TÂM — Feature engineering & risk scoring
│   ├── dbo_vw_summary_overview_View.sql   # KPI tổng quan
│   ├── dbo_vw_summary_borrower_View.sql   # Phân tích người vay
│   ├── dbo_vw_summary_loan_risk_View.sql  # Phân tích khoản vay
│   ├── dbo_vw_summary_financial_View.sql  # Phân tích tài chính
│   ├── dbo_vw_summary_early_warning_View.sql  # Cảnh báo sớm rủi ro
│   ├── dbo_vw_summary_country_View.sql    # So sánh theo quốc gia
│   ├── dbo_vw_geo_map_View.sql            # Dữ liệu bản đồ địa lý
│   └── dbo_vw_scatter_data_View.sql       # Dữ liệu scatter plots
│
└──  SQLQuery21.sql                      # Queries kiểm tra & verify views
```

---

## 11. Công nghệ sử dụng

### Python & Libraries

| Thư viện | Mục đích |
|----------|---------|
| `pandas`, `numpy` | Xử lý dữ liệu |
| `matplotlib`, `seaborn` | Trực quan hóa |
| `scikit-learn` | Machine Learning pipeline |
| `imbalanced-learn (SMOTE)` | Xử lý mất cân bằng lớp |
| `scipy.stats` | Kiểm định thống kê (Chi-square, Mann-Whitney) |

### Mô hình ML

- `LogisticRegression` (Baseline — dễ giải thích)
- `RandomForestClassifier` (Ensemble, Feature Importance)
- `GradientBoostingClassifier` (**Best model** — ROC-AUC > 0,90)

### Database & SQL

- **Microsoft SQL Server** (NovaBank database)
- 9 SQL Views với kiến trúc phân tầng rõ ràng
- BigQuery-compatible SQL queries trong Appendix

### Visualization & BI

- Power BI (kết nối qua SQL Views)
- `vw_geo_map` → Power BI Map Visual
- `vw_scatter_data` → Scatter Plot

---
*Framework: Credit Risk Analytics for Consumer Lending / Fintech*
*Tác giả: PhamNgocTheKieu | Ngày: 05/2026*
