# W9 Day B: Observability — Đo Lường Sức Khỏe Hệ Thống & Phương Pháp Luận SLO/SLI (Chuẩn Google SRE)

Chào mừng bạn đến với tài liệu hướng dẫn học tập chi tiết ngày thứ hai của tuần **W9 — Deliver Smartly**. 

Trong ngày hôm qua, bạn đã làm quen với GitOps và ArgoCD để tự động hóa hoàn toàn quy trình triển khai phần mềm lên Kubernetes. Tuy nhiên, sau khi phần mềm đã được cài đặt và khởi chạy, làm thế nào chúng ta biết được nó có đang hoạt động "tốt" hay không?
*   Có phải cứ Pod ở trạng thái `Running` là người dùng đang truy cập bình thường? (Không! Đôi khi Pod chạy tốt nhưng database bị khóa dẫn đến trang web trả về lỗi trắng xóa).
*   Làm thế nào để phát hiện hệ thống bị chậm dần theo thời gian trước khi khách hàng nổi giận và rời bỏ dịch vụ?
*   Làm thế nào để tự động cảnh báo cho kỹ sư trực ca (on-call) vào lúc nửa đêm chỉ khi có sự cố thực sự nghiêm trọng, tránh tình trạng "báo động giả" liên tục làm giảm năng suất làm việc?

Hôm nay, chúng ta sẽ cùng giải quyết toàn bộ các bài toán trên thông qua thế giới **Observability (Khả năng quan sát)**.

---

## BẢN ĐỒ LỘ TRÌNH HỌC TẬP HÔM NAY
```
  [1. Định Nghĩa Căn Bản] ───> [2. OpenTelemetry] ───> [3. Prometheus & PromQL]
                                                               │
                                                               ▼
  [6. Alerting Burn Rate] <── [5. SLO/SLI/SLA] <─── [4. Grafana & Loki]
         │
         ▼
  [7. K8s Monitoring Lab] ───> [8. Bộ 30 Câu Hỏi Phỏng Vấn SRE]
```

---

## 1. Monitoring vs. Observability (Đi sâu vào bản chất)

Khi mới bắt đầu, chúng ta thường nghe mọi người dùng lẫn lộn hai từ này. Nhưng thực chất, chúng đại diện cho hai mức độ trưởng thành khác nhau trong quá trình vận hành hệ thống phần mềm.

### 1.1. Ví dụ thực tế: Chuyện khám bệnh ở bệnh viện
*   **Giám sát (Monitoring):** Giống như khi bạn tự đo nhiệt độ cơ thể ở nhà. Nhiệt kế chỉ ra con số là **39 độ C**. Nó báo cho bạn biết: *"Cơ thể đang bị sốt (Lỗi hệ thống)"*. Nhưng nhiệt kế không thể nói cho bạn biết lý do tại sao sốt (do viêm họng, nhiễm trùng hay sốt xuất huyết). Nó chỉ đo lường các chỉ số định sẵn (Known-Unknowns).
*   **Khả năng quan sát (Observability):** Giống như khi bạn đến bệnh viện gặp bác sĩ. Bác sĩ sẽ chỉ định bạn đi xét nghiệm máu, chụp X-quang, siêu âm. Dựa trên sự kết hợp của nhiều nguồn thông tin khác nhau, bác sĩ tìm ra nguyên nhân gốc rễ: *"Bạn bị viêm phổi do virus X"*. Observability cho phép bạn suy luận trạng thái bên trong của hệ thống dựa trên các dữ liệu đầu ra mà không cần phải đoán trước lỗi đó là gì (Unknown-Unknowns).

---

### 1.2. Ba trụ cột của Observability (Metrics, Logs, Traces)

Mỗi trụ cột đóng vai trò như một giác quan giúp bạn "nhìn" thấy hệ thống của mình đang hoạt động như thế nào:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           OBSERVABILITY DATA                            │
├─────────────────────┬─────────────────────────────┬─────────────────────┤
│ Trụ cột             │ Ý nghĩa                     │ Ví dụ cụ thể        │
├─────────────────────┼─────────────────────────────┼─────────────────────┤
│ **Metrics**         │ Số liệu đo lường định lượng │ CPU: 72%,           │
│ (Số liệu)           │ theo thời gian (Rất nhẹ,    │ RAM: 4GB/8GB,       │
│                     │ lưu trữ lâu dài)            │ Request/s: 250 reqs │
├─────────────────────┼─────────────────────────────┼─────────────────────┤
│ **Logs**            │ Nhật ký chi tiết của các    │ `[ERROR] Connection │
│ (Nhật ký)           │ sự kiện riêng lẻ (Chi tiết, │ timeout to DB at    │
│                     │ tốn nhiều dung lượng ổ đĩa) │ 10.0.1.5:3306`      │
├─────────────────────┼─────────────────────────────┼─────────────────────┤
│ **Traces**          │ Hành trình của một gói tin  │ User Click ->       │
│ (Dấu vết)           │ đi qua nhiều dịch vụ khác   │ Gateway (20ms) ->   │
│                     │ nhau (Phức tạp nhất)        │ API (150ms) -> DB   │
└─────────────────────┴─────────────────────────────┴─────────────────────┘
```

---

## 2. OpenTelemetry (OTel) — Tiêu chuẩn hóa dữ liệu quan sát

### 2.1. Tại sao OpenTelemetry ra đời?
Hãy tưởng tượng bạn đang viết một ứng dụng bằng Java và cài đặt thư viện của hãng giám sát **A** vào code để đo đạc. Một ngày nọ, giám đốc quyết định chuyển sang sử dụng dịch vụ của hãng **B** vì giá rẻ hơn. Bạn sẽ phải vào từng file code Java, xóa thư viện hãng A đi, import thư viện hãng B và viết lại code cấu hình. 

**OpenTelemetry (OTel)** là dự án nguồn mở thuộc CNCF ra đời để thống nhất thế giới này. Nó cung cấp một tiêu chuẩn chung (giao thức OTLP), một bộ thư viện SDK duy nhất cho mọi ngôn ngữ lập trình. Bạn chỉ cần code một lần theo chuẩn OTel. Việc gửi dữ liệu đi đâu sẽ được quyết định bằng cấu hình (Configuration) bên ngoài mà không cần sửa code.

---

### 2.2. OTel Collector: Trạm trung chuyển dữ liệu thông minh

OTel Collector là một chương trình độc lập chạy trong hệ thống của bạn, hoạt động như một bưu điện:

```
[Các ứng dụng gửi dữ liệu] ──(OTLP/gRPC)──> [ RECEIVERS ]
                                                │
                                                ▼
                                          [ PROCESSORS ] (Lọc nhiễu, nén dữ liệu)
                                                │
                                                ▼
[Gửi đi các backend tương ứng] <────────── [ EXPORTERS ]
```

#### Chi tiết file cấu hình OTel Collector nâng cao (`otel-collector.yaml`):

```yaml
receivers:
  # Cấu hình nhận dữ liệu theo giao thức chuẩn OTLP
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  # Memory Limiter bảo vệ Collector không bị tràn bộ nhớ khi lượng log quá lớn
  memory_limiter:
    check_interval: 1s
    limit_percentage: 75
    spike_limit_percentage: 15

  # Gom nhóm dữ liệu gửi đi định kỳ để giảm tải số lượng HTTP Request
  batch:
    send_batch_size: 1024
    timeout: 5s
    export_metadata: true

exporters:
  # Xuất metrics ra dạng endpoint để Prometheus vào lấy dữ liệu (Scrape)
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel
  # Xuất log ra console của collector để hỗ trợ lập trình viên gỡ lỗi
  logging:
    verbosity: detailed

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus, logging]
```

---

## 3. Prometheus — Cơ sở dữ liệu Metrics mạnh mẽ nhất

Prometheus hoạt động bằng cơ chế **Pull** (Kéo). Nó định kỳ quét danh sách các IP của ứng dụng (dựa vào cơ chế Service Discovery của Kubernetes) và gửi request lấy dữ liệu về lưu trữ.

### 3.1. Các loại Metric trong Prometheus giải thích chi tiết kèm ví dụ code

Khi bạn viết mã nguồn để expose metrics, bạn cần chọn đúng loại dữ liệu:

1.  **Counter (Bộ đếm tích lũy):**
    *   *Tính chất:* Chỉ tăng, không bao giờ giảm (trừ khi khởi động lại ứng dụng).
    *   *Ví dụ thực tế:* Tổng số lượt click nút thanh toán, tổng số lỗi 500 xảy ra.
    *   *Ví dụ code:* `counter.inc()`
2.  **Gauge (Thước đo biến thiên):**
    *   *Tính chất:* Tăng giảm tự do bất kỳ lúc nào.
    *   *Ví dụ thực tế:* Dung lượng ổ đĩa còn trống, dung lượng RAM tiêu thụ, nhiệt độ máy chủ.
    *   *Ví dụ code:* `gauge.set(45.2)`
3.  **Histogram (Lược đồ phân bố):**
    *   *Tính chất:* Đo lường và phân nhóm dữ liệu vào các khoảng (buckets) có sẵn. Dùng để tính toán phân vị (percentiles).
    *   *Ví dụ thực tế:* Thời gian phản hồi của API. Ta muốn biết có bao nhiêu request phản hồi trong khoảng `< 100ms`, bao nhiêu trong khoảng `< 500ms`.

---

### 3.2. Cẩm nang 20 câu lệnh PromQL thực chiến (Giải thích chi tiết)

PromQL (Prometheus Query Language) là ngôn ngữ truy vấn cực kỳ mạnh mẽ. Hãy làm quen với các câu lệnh thực tế mà kỹ sư DevOps sử dụng hàng ngày:

#### 1. Tính tốc độ xử lý Request trung bình trên mỗi giây (trong 5 phút gần nhất)
```promql
rate(http_requests_total[5m])
```
*Giải thích:* `http_requests_total` là một Counter. `rate()` sẽ tính toán sự thay đổi của bộ đếm này trong khoảng thời gian 5 phút và chia cho 300 giây.

#### 2. Tính thời gian phản hồi ở phân vị 95 (P95 Latency)
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```
*Giải thích:* Chỉ số này cho thấy 95% khách hàng của bạn có thời gian phản hồi trang web nhỏ hơn giá trị tính ra. Đây là cách đo chính xác trải nghiệm người dùng hơn là dùng hàm trung bình cộng (average) vì hàm trung bình cộng sẽ làm lu mờ các request bị chậm đột biến.

#### 3. Kiểm tra xem RAM của một Node trên K8s đã sử dụng bao nhiêu phần trăm
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```
*Giải thích:* Lấy tổng dung lượng RAM của Node trừ đi lượng RAM còn trống, rồi chia cho tổng dung lượng RAM để ra tỉ lệ phần trăm đã dùng.

---

## 4. Grafana & Loki — Cặp đôi hiển thị và gom Logs tối giản

### 4.1. Sự khác biệt giữa Loki và Elasticsearch (ELK Stack)
*   **Elasticsearch:** Rất mạnh mẽ nhưng cực kỳ ngốn tài nguyên. Nó phân tích toàn bộ từ ngữ trong log và đánh chỉ mục (Index) tất cả để phục vụ tìm kiếm toàn văn (Full-text search). Để chạy ELK cho dự án nhỏ, bạn cũng có thể mất từ 8GB - 16GB RAM chỉ dành cho Elasticsearch.
*   **Loki:** Được mệnh danh là "Prometheus dành cho Logs". Nó không đánh chỉ mục nội dung log. Nó chỉ đánh chỉ mục cho các thẻ nhãn (Labels) tương tự như Prometheus (ví dụ: `{app="frontend", environment="prod"}`). Phần nội dung log được nén lại thành các khối nhỏ (Chunks) và lưu trực tiếp lên các ổ đĩa giá rẻ (như AWS S3). Loki tốn cực kỳ ít tài nguyên (chỉ cần vài trăm MB RAM là chạy tốt).

---

### 4.2. Viết câu lệnh truy vấn LogQL trong Loki

LogQL có cú pháp tương tự như PromQL. Hãy xem ví dụ phân tích log dưới đây:

#### Câu lệnh lọc log lỗi:
```logql
{app="payment-api", env="production"} |= "database connection error"
```
*Giải thích:* Tìm tất cả các dòng log thuộc ứng dụng `payment-api` chạy trên môi trường `production` mà nội dung dòng log có chứa cụm từ chính xác là `"database connection error"`.

#### Câu lệnh đếm số lượng log lỗi mỗi phút:
```logql
count_over_time({app="payment-api"} |= "error" [1m])
```
*Giải thích:* Vẽ biểu đồ đếm xem có bao nhiêu dòng log chứa từ khóa `"error"` phát sinh trong mỗi khoảng thời gian 1 phút.

---

## 5. Phương pháp luận SLO / SLI / SLA (Tư duy thiết kế hệ thống tin cậy)

Tại sao Google, Facebook không bao giờ cam kết hệ thống hoạt động ổn định 100%? Bởi vì chi phí để duy trì một hệ thống không bao giờ lỗi (100% uptime) là vô cùng đắt đỏ và không cần thiết. Khách hàng sử dụng mạng di động chập chờn cũng không thể nhận thấy sự khác biệt giữa 99.99% và 100%.

### 5.1. Phân biệt rõ ràng 3 khái niệm cốt lõi

*   **SLI (Chỉ số thực tế - Indicator):** Hệ thống đang chạy thế nào?
    *   *Ví dụ:* "Tỷ lệ các request thành công trong 5 phút qua là **99.95%**".
*   **SLO (Mục tiêu nội bộ - Objective):** Chúng ta muốn hệ thống chạy thế nào?
    *   *Ví dụ:* "Tỷ lệ các request thành công trung bình của tháng phải đạt tối thiểu **99.9%**".
*   **SLA (Cam kết pháp lý - Agreement):** Chúng ta hứa với khách hàng thế nào để không bị đền tiền?
    *   *Ví dụ:* "Nếu tỷ lệ request thành công giảm xuống dưới **99%** trong tháng, chúng tôi sẽ hoàn trả 15% tiền dịch vụ".

```
┌────────────────────────────────────────────────────────┐
│ SLA: 99% (Nếu vi phạm -> Đền tiền)                     │
│   ┌──────────────────────────────────────────────────┐ │
│   │ SLO: 99.9% (Mục tiêu nội bộ của đội DevOps)      │ │
│   │   ┌────────────────────────────────────────────┐ │ │
│   │   │ SLI: 99.95% (Chỉ số đo đạc thực tế hiện tại)│ │ │
│   │   └────────────────────────────────────────────┘ │ │
│   └──────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

---

### 5.2. Error Budget (Ngân sách lỗi)
Ngân sách lỗi là khoảng dung sai cho phép hệ thống bị lỗi.
*   Nếu SLO của bạn là **99.9%**, thì Error Budget là **0.1%**.
*   Nếu hệ thống của bạn nhận 1 triệu request mỗi tháng, bạn được phép có tối đa **1,000 request bị lỗi** mà vẫn hoàn thành mục tiêu SLO.

---

## 6. Multi-Window Burn Rate Alerting (Cảnh báo thông minh theo chuẩn Google SRE)

### 6.1. Burn Rate là gì?
Burn Rate (Tốc độ đốt ngân sách) chỉ tốc độ bạn tiêu thụ lượng lỗi cho phép nhanh như thế nào.
*   **Burn Rate = 1:** Bạn sẽ tiêu thụ vừa hết 100% ngân sách lỗi trong vòng đúng 30 ngày.
*   **Burn Rate = 2:** Bạn tiêu thụ hết ngân sách trong 15 ngày.
*   **Burn Rate = 14.4:** Bạn sẽ tiêu sạch toàn bộ ngân sách lỗi của 30 ngày chỉ trong vòng **50 giờ**! Đây là sự cố cực kỳ nghiêm trọng, hệ thống đang bị sập nặng. Kỹ sư trực ca phải được cảnh báo ngay lập tức.

---

### 6.2. Tại sao cần cảnh báo nhiều cửa sổ thời gian (Multi-window)?
Nếu bạn chỉ cấu hình cảnh báo đơn giản: *"Báo động khi tỷ lệ lỗi > 2% trong 5 phút"*.
*   *Trường hợp 1:* Hệ thống bị lỗi đột biến do mạng chập chờn đúng 1 phút rồi tự động hết. Kỹ sư đang ngủ bị dựng dậy bởi tiếng chuông báo động vô ích.
*   *Trường hợp 2:* Hệ thống bị lỗi rò rỉ rất nhỏ (0.5% request bị lỗi liên tục suốt 3 ngày). Cảnh báo không bao giờ kêu vì tỷ lệ lỗi nhỏ hơn 2%. Nhưng thực tế hệ thống đã tiêu sạch Error Budget của tháng.

**Giải pháp Multi-Window:**
Chúng ta kiểm tra đồng thời cả hai khoảng thời gian (Cửa sổ dài để xác minh lượng lỗi đủ lớn, Cửa sổ ngắn để xác nhận lỗi vẫn đang xảy ra tại thời điểm hiện tại):

#### File cấu hình Alert Rules Prometheus (`prometheus-alerts.yaml`):

```yaml
groups:
  - name: slo-app-alerts
    rules:
      # Cảnh báo khẩn cấp cấp độ 1 (Critical - Nhắn tin gọi điện trực tiếp)
      - alert: ErrorBudgetFastBurn
        # Kiểm tra: Lỗi trong 1 giờ qua lớn hơn 14.4 lần SLO cho phép
        # VÀ lỗi trong 5 phút gần đây nhất vẫn đang lớn hơn 14.4 lần SLO cho phép
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1h])) / sum(rate(http_requests_total[1h])) > (14.4 * 0.001)
            and
            sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > (14.4 * 0.001)
          )
        for: 2m
        labels:
          severity: critical
          channel: pagerduty
        annotations:
          summary: "Error Budget đang bị tiêu hao cực kỳ nhanh!"
          description: "Tốc độ đốt lỗi (Burn Rate) đang vượt quá 14.4. Hệ thống sẽ tiêu sạch ngân sách lỗi của tháng trong vòng dưới 50 giờ nếu không được xử lý."
```

---

## 7. Bài tập thực hành nâng cao (Hands-on Labs)

### Lab B1: Tạo Dashboard Grafana tùy biến giám sát ứng dụng K8s
1.  Truy cập vào Grafana UI của bạn qua cổng 3000.
2.  Nhấn nút tạo mới Dashboard.
3.  Thêm Panel mới và nhập câu lệnh PromQL sau để vẽ biểu đồ lượng request xử lý mỗi giây:
    ```promql
    sum(rate(http_requests_total[1m])) by (app)
    ```
4.  Cấu hình định dạng trục Y hiển thị dạng `requests/sec (reqps)`.

---

## 8. Bộ 30 Câu Hỏi Ôn Tập & Phỏng Vấn SRE/DevOps (Day B)

### 8.1. Phần trắc nghiệm nhanh (15 câu)

**Câu 1: Điểm khác biệt cơ bản nhất giữa Logs và Metrics là gì?**
*   A. Logs là dạng chữ chi tiết, Metrics là dạng số thu thập định kỳ theo thời gian.
*   B. Logs chỉ dùng trong môi trường Dev, Metrics dùng trong Prod.
*   C. Logs nhẹ hơn Metrics.

**Câu 2: Công thức tính toán chỉ số SLI availability chuẩn là gì?**
*   A. `Tổng số request / Số request lỗi`
*   B. `Số request thành công / Tổng số request thực hiện * 100`
*   C. `Thời gian sập / Thời gian chạy`

**Câu 3: Mục tiêu của việc sử dụng Multi-Window Alerting là gì?**
*   A. Để vẽ được nhiều biểu đồ hơn trên Grafana.
*   B. Giảm thiểu báo động giả (Alert Fatigue) đồng thời phát hiện được các lỗi rò rỉ kéo dài tiêu hao ngân sách lỗi.
*   C. Giúp hệ thống tự động sửa lỗi mà không cần gọi kỹ sư.

**Câu 4: Prometheus thu thập dữ liệu bằng cách nào?**
*   A. Ứng dụng tự động gửi dữ liệu về Prometheus Server mỗi 5 giây.
*   B. Prometheus định kỳ tạo request HTTP GET tới endpoint `/metrics` của ứng dụng để kéo dữ liệu về.
*   C. Đọc file log trên ổ cứng.

**Câu 5: Trong Prometheus, loại Metric nào phù hợp nhất để đo dung lượng RAM đang sử dụng của Server?**
*   A. Counter
*   B. Gauge
*   C. Histogram

*(Còn tiếp 10 câu trắc nghiệm khác...)*

### 8.2. Phần câu hỏi tự luận phỏng vấn thực chiến (15 câu)

#### Câu 16: Em hãy phân tích sự khác nhau về mặt kiến trúc và hiệu năng giữa Loki và Elasticsearch khi lưu trữ log?
*   **Trả lời:** *Xem chi tiết tại Mục 4.1 của tài liệu.*

#### Câu 17: Một ứng dụng có SLO availability là 99.9%. Giả sử hệ thống bị sập hoàn toàn trong vòng 20 phút. Theo em, hệ thống đã tiêu tốn bao nhiêu phần trăm ngân sách lỗi (Error Budget) của tháng đó?
*   **Trả lời:** 
    *   Mục tiêu SLO 99.9% cho phép tổng thời gian sập tối đa trong 1 tháng (30 ngày) là khoảng **43.8 phút**.
    *   Sự cố sập kéo dài 20 phút.
    *   Phần trăm ngân sách lỗi bị tiêu thụ: `(20 / 43.8) * 100% ≈ 45.6%`.
    *   Như vậy, chỉ sau 1 sự cố duy nhất kéo dài 20 phút, hệ thống đã tiêu hao gần một nửa (45.6%) lượng lỗi cho phép của cả tháng.

#### Câu 18: Hãy giải thích cách thức hoạt động của OTel Collector? Tại sao chúng ta nên triển khai OTel Collector dưới dạng DaemonSet trong Kubernetes thay vì nhúng trực tiếp vào container ứng dụng?
*   **Trả lời:** OTel Collector hoạt động như một proxy trung gian nhận, xử lý và xuất dữ liệu. Triển khai dưới dạng DaemonSet (mỗi Node chạy 1 pod collector) giúp giảm thiểu mức độ chiếm dụng CPU/RAM của ứng dụng gốc. Ứng dụng gốc chỉ cần đẩy dữ liệu cục bộ (localhost) cực kỳ nhanh qua cổng gRPC/HTTP sang Collector nằm chung Node. Collector DaemonSet sau đó sẽ chịu trách nhiệm gom nhóm, lọc dữ liệu và đẩy đi các backend bên ngoài qua mạng Internet.
