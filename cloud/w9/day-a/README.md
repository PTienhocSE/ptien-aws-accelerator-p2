# W9 Day A: GitOps & CI/CD - Cẩm Nang Đào Tạo Toàn Diện Cho Kỹ Sư DevOps/Cloud (Mới Bắt Đầu)

Chào mừng bạn đến với tài liệu hướng dẫn tự học chi tiết của ngày đầu tiên tuần **W9 — Deliver Smartly**. 

Ở tuần W8, bạn đã thành công trong việc xây dựng một cụm Kubernetes (Minikube) trên môi trường AWS EC2, mở cổng, cấu hình Application Load Balancer (ALB) và kiểm tra khả năng truy cập. Tuy nhiên, cách làm đó vẫn còn rất thủ công: bạn phải viết file YAML trên máy chủ, gõ lệnh `kubectl apply -f <tên_file>` trực tiếp từ dòng lệnh. 

**Tại sao cách làm thủ công này lại nguy hiểm trong môi trường thực tế?**
1.  **Thiếu kiểm soát lịch sử:** Ai đã thay đổi số lượng bản sao (replicas) của dịch vụ? Khi nào? Tại sao lại sửa? Không có câu trả lời rõ ràng.
2.  **Lệch cấu hình (Configuration Drift):** Một kỹ sư khác có thể SSH vào server và dùng lệnh `kubectl edit` để sửa trực tiếp một cấu hình nào đó. File YAML trên máy cá nhân hoặc trên Git của bạn lúc này sẽ hoàn toàn khác với những gì đang chạy trên server.
3.  **Khó khôi phục:** Nếu hệ thống bị sập do cấu hình sai, bạn không thể dễ dàng quay lại trạng thái cũ ngay lập tức vì không biết trước đó hệ thống đang chạy phiên bản nào.

Hôm nay, chúng ta sẽ giải quyết triệt để vấn đề này bằng bộ đôi công nghệ **CI/CD (GitHub Actions)** và **GitOps (ArgoCD)**.

---

## BẢN ĐỒ LỘ TRÌNH HỌC TẬP HÔM NAY
```
  [1. CI/CD Căn Bản] ────> [2. GitHub Actions] ────> [3. Tư Duy GitOps]
                                                             │
                                                             ▼
  [6. Rollback Thực Tế] <─── [5. App-of-Apps] <─── [4. ArgoCD Thực Chiến]
         │
         ▼
  [7. FluxCD & Best Practices] ───> [8. Bộ 30 Câu Hỏi Phỏng Vấn]
```

---

## 1. CI/CD là gì? (Giải thích trực quan từ con số 0)

Để hiểu về CI/CD, chúng ta hãy tạm quên đi các thuật ngữ kỹ thuật phức tạp như Docker, Kubernetes hay Jenkins. Hãy tưởng tượng bạn đang xây dựng một **Nhà Máy Sản Xuất Bánh Mì**.

*   **Thời kỳ thủ công (Không có CI/CD):**
    *   Mỗi khi người thợ làm bánh (Developer) nghĩ ra một công thức pha bột mới (Code mới), người đó tự tay nhào bột, tự nướng thử bằng lò cá nhân. Sau đó, họ mang ổ bánh đó ra quầy bán trực tiếp cho khách hàng (Deploy thủ công lên Production).
    *   **Hậu quả:** Có hôm bánh ngon, có hôm bánh bị mặn, có hôm bánh bị cháy đen do nhiệt độ lò của khách hàng khác với lò cá nhân. Khách hàng phàn nàn, người thợ phải vội vàng chạy ra quầy rút bánh về và làm lại từ đầu.
*   **Thời kỳ hiện đại (Có quy trình CI/CD):**
    *   Người thợ làm bánh chỉ cần viết công thức lên bảng điều khiển chung của nhà máy (Git Commit).
    *   **Băng chuyền CI (Continuous Integration):** Một hệ thống robot tự động nhận công thức, tự cân đo lượng bột, tự kiểm tra xem lượng muối có vượt quá mức an toàn hay không (Chạy Unit Test và Linting). Nếu công thức ghi sai (ví dụ: thiếu nước), robot sẽ ngay lập tức phát loa cảnh báo và dừng băng chuyền (Build Fail).
    *   **Băng chuyền CD (Continuous Delivery/Deployment):** Nếu bánh đi qua khâu kiểm tra chất lượng đạt điểm 10, hệ thống tự động đóng gói bánh vào hộp chuẩn (Docker Image) rồi chuyển tới quầy trưng bày. Nếu hệ thống tự động đưa thẳng lên đĩa của khách hàng, đó là **Continuous Deployment**. Nếu hệ thống xếp vào kho và chờ người quản lý bấm nút xác nhận mới mang ra cho khách, đó là **Continuous Delivery**.

---

### 1.1. Tích hợp liên tục (Continuous Integration - CI)
CI là một hoạt động phát triển phần mềm trong đó các thành viên của dự án tích hợp code của họ vào một nhánh chính (thường là `main` hoặc `master`) ít nhất một lần hoặc nhiều lần mỗi ngày. Mỗi lần tích hợp sẽ được kiểm tra tự động bằng cách build và chạy test để phát hiện lỗi nhanh nhất có thể.

**Các bước điển hình của một pipeline CI:**
```
[Lập trình viên push code] 
       │
       ▼
[Kích hoạt Workflow tự động] ──> [Kiểm tra cú pháp (Linting)]
                                       │
                                       ▼
[Chạy Security Scan] <─────────── [Chạy Unit Tests (Kiểm thử đơn vị)]
       │
       ▼
[Build Docker Image thử nghiệm] ──> [Thông báo kết quả qua Slack/Email]
```

---

### 1.2. Chuyển giao liên tục (Continuous Delivery) vs. Triển khai liên tục (Continuous Deployment)

Mặc dù cả hai đều viết tắt là **CD**, nhưng mục tiêu cuối cùng của chúng có sự khác biệt lớn về vai trò của con người trong quy trình:

| Tiêu chí | Continuous Delivery (Chuyển giao liên tục) | Continuous Deployment (Triển khai liên tục) |
| :--- | :--- | :--- |
| **Quyết định deploy** | Cần **sự can thiệp của con người** (Bấm nút phê duyệt - Manual Approval). | **Hoàn toàn tự động**. Không có sự can thiệp của con người. |
| **Môi trường phù hợp** | Các hệ thống lớn, ngân hàng, y tế, doanh nghiệp lớn cần kiểm soát chặt chẽ chu kỳ release. | Các startup công nghệ, phần mềm SaaS (như Facebook, Netflix) cần ra tính năng mới liên tục nhiều lần trong ngày. |
| **Yêu cầu hệ thống test**| Yêu cầu hệ thống test tự động ở mức cơ bản đến trung bình. | Yêu cầu hệ thống test tự động cực kỳ khắt khe, bao phủ 99% các trường hợp lỗi (Test Coverage). |
| **Mức độ rủi ro** | Thấp hơn vì có bước con người kiểm duyệt cuối cùng. | Cao hơn, đòi hỏi phải có cơ chế tự động rollback (Canary/Blue-Green) thông minh. |

---

## 2. GitHub Actions — Nền tảng CI/CD thế hệ mới

GitHub Actions (GHA) đã nhanh chóng trở thành công cụ CI/CD phổ biến nhất hiện nay nhờ lợi thế tích hợp trực tiếp vào kho lưu trữ mã nguồn GitHub. Bạn không cần phải dựng một server Jenkins riêng, không cần bảo trì hạ tầng phức tạp.

### 2.1. Cấu trúc phân cấp của GitHub Actions
Để viết được một file cấu hình GitHub Actions không bị lỗi, bạn phải hiểu rõ sơ đồ phân cấp dưới đây:

```
┌─────────────────────────────────────────────────────────────────┐
│ WORKFLOW (Định nghĩa trong 1 file YAML)                         │
│   Trigger: push, pull_request, schedule...                      │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ JOB 1 (Chạy trên Runner VM riêng biệt - ví dụ: Ubuntu)   │  │
│   │                                                          │  │
│   │   Step 1: uses: actions/checkout@v4 (Action dùng sẵn)   │  │
│   │   Step 2: run: npm run build (Lệnh Shell tự viết)        │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ JOB 2 (Chạy song song hoặc chạy sau JOB 1)               │  │
│   │   Step 1: run: echo "Deploying..."                       │  │
│   └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

*   **Workflow:** Là quy trình tự động lớn nhất. Một dự án có thể có hàng chục workflow. Chúng được lưu trong thư mục `.github/workflows/` dưới định dạng `.yml` hoặc `.yaml`.
*   **Job:** Là một nhóm các bước (Steps) thực thi trên cùng một máy ảo (Runner). Các Job mặc định chạy song song để tiết kiệm thời gian. Nếu muốn Job B chỉ chạy sau khi Job A đã thành công, bạn phải dùng thuộc tính `needs: job-a`.
*   **Step:** Là một tác vụ nhỏ trong Job. Các Step chạy tuần tự từ trên xuống dưới trên cùng một máy ảo, giúp chúng có thể chia sẻ dữ liệu qua lại với nhau (ví dụ: step 1 tạo file, step 2 đọc file đó).
*   **Action:** Là một chương trình được đóng gói sẵn nhằm thực hiện một nhiệm vụ phổ biến (ví dụ: login vào AWS, cài đặt Java, gửi tin nhắn Slack). Bạn có thể tìm thấy hàng ngàn Action miễn phí trên [GitHub Marketplace](https://github.com/marketplace).
*   **Runner:** Máy ảo (Virtual Machine) do GitHub cấp miễn phí (hoặc bạn tự cài đặt trên server của mình - Self-hosted Runner). Có sẵn các hệ điều hành: Ubuntu Linux, Windows Server, macOS.

---

### 2.2. Giải thích chi tiết từng dòng file Workflow Node.js (Ví dụ thực tế)

Dưới đây là một file workflow CI hoàn chỉnh cho ứng dụng Node.js. Hãy đọc kỹ phần giải thích chi tiết cho từng dòng để hiểu cách hệ thống hoạt động:

```yaml
# Tên hiển thị trên tab Actions của GitHub
name: 🚀 Ứng dụng Node.js - Tích hợp liên tục (CI)

# Định nghĩa các sự kiện (Events) sẽ kích hoạt workflow này
on:
  # Chạy khi có hành động push code
  push:
    branches:
      - main
      - 'releases/**' # Chạy khi push lên các branch như releases/v1, releases/v2
  # Chạy khi có Pull Request nhắm vào branch main
  pull_request:
    branches:
      - main

# Định nghĩa các công việc cần chạy
jobs:
  # Tên định danh của Job (viết liền, không dấu)
  build-and-test:
    name: 🛠️ Biên dịch và Chạy kiểm thử tự động
    # Hệ điều hành của máy ảo Runner do GitHub cấp
    runs-on: ubuntu-22.04

    # Liệt kê tuần tự các bước chạy
    steps:
      # Bước 1: Checkout mã nguồn về máy ảo
      - name: 📥 Kéo code từ GitHub về máy ảo
        uses: actions/checkout@v4

      # Bước 2: Khởi tạo môi trường Node.js phiên bản 20
      - name: 🟢 Cài đặt môi trường Node.js v20
        uses: actions/setup-node@v4
        with:
          node-version: 20
          # Bật tính năng cache thư viện để lần chạy sau nhanh hơn
          cache: 'npm'

      # Bước 3: Cài đặt các thư viện phụ thuộc (Dependencies)
      - name: 📦 Cài đặt thư viện (Dependencies)
        # Lệnh npm ci giúp cài đặt chính xác các phiên bản ghi trong file package-lock.json
        run: npm ci

      # Bước 4: Kiểm tra định dạng code (Linting)
      - name: 🔍 Kiểm tra chuẩn định dạng code (Linter)
        run: npm run lint

      # Bước 5: Chạy các bài test đơn vị (Unit Tests)
      - name: 🧪 Chạy các bài kiểm thử tự động (Unit Test)
        run: npm test
```

---

### 2.3. Quy trình CI/CD cho Terraform (Plan on PR & Apply on Merge)

Đây là quy trình bắt buộc phải biết đối với kỹ sư Cloud/IaC (Infrastructure as Code). Khi làm việc nhóm, bạn không bao giờ được phép tự chạy `terraform apply` từ máy tính cá nhân. Tất cả phải đi qua GitHub Actions.

#### Kịch bản hoạt động:
1.  **Người dùng tạo Pull Request (PR):**
    *   Hệ thống khởi chạy.
    *   Tự động chạy `terraform plan`.
    *   **Điểm đặc biệt:** Hệ thống sẽ xuất kết quả plan ra dạng văn bản và tự động đăng bình luận (comment) vào chính PR đó để các kỹ sư khác xem và review mà không cần mở terminal lên gõ lệnh.
2.  **Manager phê duyệt và Merge PR vào branch main:**
    *   Hệ thống nhận thấy sự thay đổi trên branch main.
    *   Khởi chạy và tự động chạy `terraform apply -auto-approve` để áp dụng thay đổi lên tài nguyên thật trên AWS.

#### Nội dung file cấu hình `.github/workflows/terraform.yml`:

```yaml
name: ☁️ Quy trình quản lý hạ tầng Terraform AWS

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

# Định nghĩa các biến môi trường dùng chung
env:
  AWS_REGION: us-east-1
  TF_VERSION: 1.7.0

jobs:
  terraform:
    name: 🛠️ Kiểm tra & Áp dụng hạ tầng
    runs-on: ubuntu-latest
    steps:
      # 1. Lấy mã nguồn
      - name: Checkout Code
        uses: actions/checkout@v4

      # 2. Đăng nhập AWS bằng Access Key bảo mật lưu trong Secrets
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # 3. Cài đặt Terraform CLI lên máy ảo
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      # 4. Khởi tạo Terraform (tải provider aws, cấu hình backend s3)
      - name: Terraform Init
        id: init
        run: terraform init

      # 5. Kiểm tra định dạng code viết đúng chuẩn thụt lề hay chưa
      - name: Terraform Format Check
        id: fmt
        run: terraform fmt -check

      # 6. Kiểm tra xem code viết có đúng cú pháp luận lý không
      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color

      # 7. Chạy thử nghiệm và hiển thị thay đổi (Chỉ chạy khi có Pull Request)
      - name: Terraform Plan
        id: plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color
        # Lệnh tiếp tục chạy ngay cả khi plan báo lỗi để chúng ta kịp xem báo cáo
        continue-on-error: true

      # 8. Đăng comment tự động lên Pull Request chứa kết quả plan
      - name: Update Pull Request Comment
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Đánh giá hạ tầng:
            *   Trạng thái Init: \`${{ steps.init.outcome }}\`
            *   Trạng thái Fmt Check: \`${{ steps.fmt.outcome }}\`
            *   Trạng thái Validate: \`${{ steps.validate.outcome }}\`
            *   Trạng thái Plan: \`${{ steps.plan.outcome }}\`

            <details><summary>Xem chi tiết kết quả Terraform Plan</summary>

            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`

            </details>

            *Người gửi: GHA Workflow*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      # 9. Áp dụng thay đổi thật (Chỉ chạy khi push code trực tiếp hoặc merge PR vào main)
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve

      # 10. Tự động dừng pipeline nếu bước plan trước đó bị lỗi cú pháp hạ tầng
      - name: Check Plan Status
        if: steps.plan.outcome == 'failure'
        run: exit 1
```

---

## 3. Tư duy GitOps (Thay đổi triệt để tư duy vận hành)

Để hiểu sâu về GitOps, hãy cùng thảo luận về một tình huống thực tế thường xảy ra ở các công ty công nghệ chưa áp dụng GitOps:

### 3.1. Sự cố "Ai đã sửa cái gì?"
Một ngày đẹp trời, trang web của công ty đột ngột bị sập. Khi kiểm tra, đội ngũ phát hiện ra cổng dịch vụ (Port) của Service Database trên Kubernetes bị đổi từ `3306` thành `3307`. 
*   **Điều tra:** Mọi người hỏi nhau trên kênh chat chung nhưng ai cũng bảo "Tôi không đụng vào". 
*   **Nguyên nhân:** Một kỹ sư trước đó đã SSH vào cluster, dùng lệnh `kubectl edit service/db` để sửa tạm thời phục vụ mục đích kiểm thử nhưng sau đó quên không sửa lại và cũng không ghi chép vào đâu cả.

**Nếu áp dụng GitOps:**
Tình huống trên hoàn toàn không thể xảy ra. Bởi vì:
1.  Kỹ sư không có quyền truy cập trực tiếp vào Cluster để gõ lệnh `kubectl` (Bảo mật tối đa).
2.  Nếu muốn đổi cổng Database, kỹ sư buộc phải sửa file YAML trên Git và tạo một Pull Request.
3.  Mọi người sẽ thảo luận trực tiếp trên Pull Request đó, phê duyệt và merge.
4.  Ngay khi merge, ArgoCD (GitOps Controller) sẽ tự động đồng bộ hóa cổng mới xuống Cluster. Lịch sử thay đổi được lưu trữ mãi mãi trên Git.

---

### 3.2. Bốn nguyên tắc trụ cột của GitOps giải thích chi tiết

1.  **Mô tả hệ thống dưới dạng Khai báo (Declarative):** 
    Thay vì viết script mô tả các bước thực thi (Imperative) như: *"Bước 1: Tạo máy ảo, Bước 2: Cài Docker, Bước 3: Pull image"* -> Cách này rất dễ lỗi nếu một bước trung gian bị gián đoạn.
    Với GitOps, bạn khai báo trạng thái mong muốn cuối cùng: *"Tôi muốn có một ứng dụng chạy Nginx version 1.25, mở cổng 80, số lượng bản sao là 3"*. K8s và GitOps Controller sẽ tự động lo liệu làm sao để đạt được trạng thái đó.
2.  **Lưu trữ trạng thái trên Git dưới dạng Bất biến (Versioned and Immutable):**
    Git lưu trữ mọi phiên bản của hệ thống. Bạn có thể dễ dàng biết được 2 tháng trước hệ thống của bạn trông như thế nào bằng cách duyệt lại lịch sử commit.
3.  **Tự động kéo thay đổi (Pulled Automatically):**
    Các Agent (như ArgoCD) cài trực tiếp trong cluster tự động định kỳ kéo cấu hình mới về, thay vì đợi bên ngoài đẩy vào. Điều này giúp ngăn chặn các cuộc tấn công chiếm quyền điều khiển hạ tầng từ bên ngoài.
4.  **Tự chữa lành và Liên tục kiểm tra (Self-Healing & Continuous Reconciliation):**
    Hãy tưởng tượng bạn có một Robot giám sát chạy liên tục mỗi 3 giây. Nếu có ai đó dùng quyền admin lén vào cluster xóa đi một Service, Robot sẽ phát hiện ngay trạng thái thực tế đang thiếu 1 Service so với file YAML trên Git. Nó lập tức tự tạo lại Service đó ngay lập tức mà không cần bất kỳ sự can thiệp nào của con người.

---

## 4. ArgoCD Thực Chiến — Cài Đặt & Cấu Hình Chi Tiết

Chúng ta sẽ tiến hành cài đặt ArgoCD trên cụm Minikube của bạn một cách bài bản nhất.

### 4.1. Hướng dẫn cài đặt nâng cao và tối ưu bảo mật

Mặc định, khi cài đặt ArgoCD bằng file yaml mặc định từ Internet, tất cả các cấu hình đều sử dụng giao thức HTTPS tự ký rất dễ bị trình duyệt chặn. Chúng ta sẽ cài đặt và cấu hình truy cập thông qua dịch vụ NodePort của Kubernetes để dễ dàng kết nối từ máy ảo AWS EC2 ra ngoài.

#### Bước 1: Khởi động Minikube (Đảm bảo minikube của bạn đang chạy tốt)
```bash
minikube status
```

#### Bước 2: Tạo namespace quản lý riêng
```bash
kubectl create namespace argocd
```

#### Bước 3: Cài đặt ArgoCD
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### Bước 4: Chờ đợi các Pod khởi chạy thành công
Sử dụng câu lệnh sau để theo dõi tiến độ khởi động (Nhấn `Ctrl + C` để thoát khi toàn bộ Pod hiển thị trạng thái `Running`):
```bash
kubectl get pods -n argocd -w
```

---

### 4.2. Hướng dẫn chi tiết cách cấu hình Service Ingress hoặc NodePort để truy cập từ ngoài Internet

Trong lab của W8, máy ảo EC2 của bạn có một IP Public. Chúng ta muốn truy cập giao diện Web UI của ArgoCD từ trình duyệt máy tính cá nhân bằng cách gọi trực tiếp cổng trên EC2.

#### Phương án 1: Chuyển đổi Service sang dạng NodePort
Mặc định, dịch vụ `argocd-server` chạy dưới dạng `ClusterIP`. Chúng ta sẽ chuyển nó sang `NodePort` bằng lệnh:
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

Sau đó, hãy kiểm tra xem Kubernetes đã cấp cổng NodePort ngẫu nhiên nào cho ArgoCD:
```bash
kubectl get svc argocd-server -n argocd
```
*Kết quả mẫu:*
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
argocd-server   NodePort   10.106.120.30   <none>        80:32154/TCP,443:30443/TCP   10m
```
Trong ví dụ trên, cổng NodePort ánh xạ cho HTTPS (cổng 443) là **30443**.

**Bây giờ, hãy sử dụng công cụ `socat` chạy ngầm trên máy ảo EC2 để chuyển tiếp traffic:**
```bash
# Chạy socat chuyển hướng từ cổng 8080 của máy ảo EC2 vào cổng 30443 của Minikube
sudo socat TCP-LISTEN:8080,fork,reuseaddr TCP:192.168.49.2:30443 &
```
*(Đảm bảo bạn đã mở cổng 8080 trong Security Group của EC2 trên AWS Console).*
Giờ đây, bạn truy cập địa chỉ: `https://<IP_PUBLIC_EC2>:8080` từ trình duyệt của mình.

---

### 4.3. Giải thích chi tiết file YAML khai báo Application của ArgoCD

Dưới đây là cấu trúc file manifest YAML khai báo Application trên ArgoCD. Đây chính là cách chúng ta quản lý ứng dụng theo triết lý "Infrastructure as Code".

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  # Tên định danh duy nhất của ứng dụng trên giao diện ArgoCD
  name: hethong-banhang-frontend
  # Ứng dụng ArgoCD phải nằm trong namespace 'argocd' để controller có thể đọc được
  namespace: argocd
spec:
  # Chỉ định project quản lý (Project dùng để phân quyền cho các đội nhóm)
  project: default

  # Nguồn chứa mã nguồn YAML cấu hình K8s
  source:
    # URL của kho lưu trữ chứa code
    repoURL: 'https://github.com/PTienhocSE/aws-tf-k8s-lab.git'
    # Chỉ định nhánh Git (ví dụ: main, develop, hoặc tag v1.0.0)
    targetRevision: HEAD
    # Thư mục cụ thể chứa file yaml bên trong repo
    path: templates

  # Nơi sẽ triển khai tài nguyên đến
  destination:
    # URL của cụm K8s. Cụm tại chỗ nơi ArgoCD đang chạy luôn có địa chỉ: kubernetes.default.svc
    server: 'https://kubernetes.default.svc'
    # Namespace đích sẽ chứa các Pod, Service của ứng dụng khi chạy
    namespace: default

  # Cấu hình chính sách tự động hóa đồng bộ
  syncPolicy:
    automated:
      # Tự động xóa các tài nguyên trên K8s nếu chúng bị xóa khỏi Git.
      # Ví dụ: bạn xóa file service.yaml trên Git, ArgoCD sẽ tự xóa Service đó trên cụm.
      prune: true
      # Tự động sửa lại trạng thái nếu có ai đó sửa đổi trực tiếp trên cụm bằng lệnh kubectl.
      selfHeal: true
    syncOptions:
      # Nếu namespace 'default' chưa có, tự động tạo mới
      - CreateNamespace=true
```

---

## 5. App-of-Apps Pattern (Quản lý dự án quy mô lớn)

Khi công ty của bạn phát triển từ 1 ứng dụng lên thành 20-30 ứng dụng khác nhau chạy cùng lúc. Việc quản lý từng file `Application` YAML riêng lẻ sẽ trở nên rời rạc và khó kiểm soát.

### 5.1. Mô hình kiến trúc App-of-Apps
Để giải quyết bài toán này, chúng ta định nghĩa một **Root Application (Ứng dụng gốc)**. Root Application này sẽ giám sát một thư mục đặc biệt trên Git. Thư mục này chỉ chứa các file YAML định nghĩa các `Application` con khác.

```
                                ┌───────────────────────────┐
                                │     Root Application      │
                                │   (Quản lý thư mục apps/)  │
                                └─────────────┬─────────────┘
                                              │
                     ┌────────────────────────┼────────────────────────┐
                     ▼                        ▼                        ▼
         ┌───────────────────────┐┌───────────────────────┐┌───────────────────────┐
         │ Application Con 1     ││ Application Con 2     ││ Application Con 3     │
         │ (database-app)        ││ (backend-app)         ││ (frontend-app)        │
         └───────────┬───────────┘└───────────┬───────────┘└───────────┬───────────┘
                     │                        │                        │
                     ▼                        ▼                        ▼
         [Deploy MySQL Pods...]   [Deploy Node.js Pods...]  [Deploy Nginx Pods...]
```

---

### 5.2. File cấu hình thực tế cho Root Application (`root-app.yaml`)

Hãy lưu file này vào repo của bạn và chạy lệnh apply thủ công một lần duy nhất. Sau này, mọi ứng dụng con chỉ cần đẩy file định nghĩa vào thư mục `cloud/w9/day-a/argocd-apps/` trên Git.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hethong-root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/PTienhocSE/aws-tf-k8s-lab.git'
    targetRevision: HEAD
    # Chỉ định thư mục chứa danh sách file YAML của các app con
    path: cloud/w9/day-a/argocd-apps
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Ví dụ file cấu hình App con lưu trong thư mục `cloud/w9/day-a/argocd-apps/database.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/PTienhocSE/aws-tf-k8s-lab.git'
    targetRevision: HEAD
    path: cloud/w9/day-a/manifests/database
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: database-zone
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 6. Sync Waves và Hooks (Kiểm soát tuyệt đối trình tự khởi động)

### 6.1. Bản chất của Sync Waves
Kubernetes mặc định chạy song song tất cả các tài nguyên được khai báo. Điều này dẫn đến lỗi nghiêm trọng khi:
*   Ứng dụng bắt đầu kết nối vào Database trong khi Database còn đang tải Docker Image và chưa sẵn sàng lắng nghe cổng.
*   Ứng dụng cố gắng đọc dữ liệu từ ConfigMap trong khi ConfigMap đó chưa được tạo ra.

ArgoCD cung cấp giải pháp **Sync Waves** (Làn sóng đồng bộ). ArgoCD sẽ sắp xếp thứ tự triển khai dựa trên giá trị nhãn cấu hình `argocd.argoproj.io/sync-wave` chạy từ thấp đến cao (giá trị có thể âm hoặc dương, mặc định là `0`).

```
Wave -5: Tạo Namespace, ServiceAccount, RBAC Roles
  │ (Hoàn thành)
  ▼
Wave -1: Tạo Secrets, ConfigMaps chứa cấu hình kết nối
  │ (Hoàn thành)
  ▼
Wave 0: Khởi chạy Database, Services nền (Redis, MySQL)
  │ (Chờ Database báo trạng thái Healthy)
  ▼
Wave 5: Triển khai Backend API, Frontend Web
```

#### Ví dụ file YAML Service Account (Wave -5):
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: common-service-account
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "-5"
```

#### Ví dụ file YAML Deployment App (Wave 5):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-backend
  namespace: default
  annotations:
    argocd.argoproj.io/sync-wave: "5"
spec:
  replicas: 2
# ... phần cấu hình container ...
```

---

## 7. Các chiến lược khôi phục hệ thống (Rollback Strategies) khi gặp lỗi

Khi phiên bản mới vừa deploy lên gặp lỗi nghiêm trọng (ví dụ: rò rỉ bộ nhớ khiến Pod restart liên tục), bạn phải hành động cực kỳ nhanh để giảm thiểu thiệt hại cho người dùng.

### 7.1. Bảng so sánh 3 phương pháp khôi phục phổ biến

| Phương pháp | Cách thực hiện | Ưu điểm | Nhược điểm | Đánh giá |
| :--- | :--- | :--- | :--- | :--- |
| **`git revert`** | Tạo commit đảo ngược thay đổi cũ trên máy cá nhân và push lên Git. | Đúng chuẩn GitOps, lưu lại toàn bộ lịch sử lỗi và lịch sử khôi phục, cực kỳ tường minh. | Chạy chậm hơn (mất thêm vài phút chạy lại pipeline CI/CD). | **Khuyên dùng nhiều nhất (Best Practice).** |
| **`kubectl rollout undo`** | Chạy lệnh gõ tay trực tiếp trên máy chủ để K8s đổi sang ReplicaSet cũ. | Chạy ngay lập tức, sửa lỗi chỉ trong vài giây. | **Không có tác dụng nếu bật Self-Heal.** ArgoCD sẽ ngay lập tức tải cấu hình lỗi từ Git xuống đè lên. | **Tránh sử dụng** trừ khi đã tắt ArgoCD. |
| **ArgoCD Manual Rollback** | Nhấn nút "Rollback" trên Web UI của ArgoCD. | Nhanh chóng, tự động tắt tính năng Auto-Sync để tránh bị đè ngược lại. | Trạng thái trên Git và Cluster tạm thời bị lệch nhau. | **Khuyên dùng khi khẩn cấp** lúc nửa đêm. |

---

## 8. Đối thủ lớn nhất của ArgoCD: FluxCD là gì?

Khi đi làm tại các doanh nghiệp lớn, bạn có thể sẽ gặp cụm K8s sử dụng **FluxCD** thay vì ArgoCD. Hãy cùng xem bảng so sánh chi tiết để chuẩn bị cho các câu hỏi phỏng vấn tuyển dụng:

```
ARCHITECTURAL DIFFERENCE:
ArgoCD: Cung cấp Web UI quản lý trực quan dạng sơ đồ cây, giao diện thân thiện, dễ cấu hình thủ công.
FluxCD: Tối giản, không có UI mặc định, quản lý 100% qua lệnh CLI và custom resource K8s, tích hợp sâu vào mã nguồn Git.
```

| Tiêu chí | ArgoCD | FluxCD |
| :--- | :--- | :--- |
| **Triết lý thiết kế** | Cung cấp một ứng dụng đầy đủ tính năng với giao diện đồ họa quản trị mạnh mẽ. | Thiết kế dạng module nhỏ gọn tuân theo triết lý của UNIX (mỗi phần làm tốt 1 việc). |
| **Cách quản lý cấu hình** | Quản lý tập trung thông qua Application Controller. | Sử dụng các GitRepository, Kustomization CRD riêng biệt. |
| **Hỗ trợ Helm** | Rất tốt, tự động render template. | Cực mạnh thông qua HelmController, có khả năng tự động cập nhật chart. |
| **Tài nguyên tiêu thụ** | Nhiều hơn (vì phải chạy Web Server, Redis...). | Rất ít, cực kỳ nhẹ và bảo mật. |

---

## 9. Bộ 30 Câu Hỏi Ôn Tập & Phỏng Vấn DevOps (Day A)

Dưới đây là danh sách câu hỏi được tổng hợp từ các buổi phỏng vấn tuyển dụng kỹ sư Cloud/DevOps thực tế. Hãy tự trả lời và đối chiếu với đáp án chi tiết.

### 9.1. Phần trắc nghiệm nhanh (15 câu)

**Câu 1: Khái niệm "Configuration Drift" nghĩa là gì?**
*   A. Cấu hình hệ thống tự động đồng bộ theo thời gian.
*   B. Sự sai lệch cấu hình giữa môi trường thực tế (K8s) và nguồn cấu hình chuẩn khai báo trên Git.
*   C. Việc chuyển đổi code từ phiên bản cũ sang phiên bản mới.

**Câu 2: Trong GitHub Actions, thuộc tính `runs-on` dùng để chỉ định điều gì?**
*   A. Các câu lệnh shell cần chạy.
*   B. Hệ điều hành và môi trường của máy ảo Runner sẽ thực thi Job.
*   C. Thời gian tối đa của Job.

**Câu 3: Mục tiêu chính của quy trình Continuous Integration (CI) là gì?**
*   A. Deploy code lên môi trường Product cho khách hàng dùng.
*   B. Tự động kiểm tra chất lượng code và phát hiện lỗi sớm nhất có thể.
*   C. Quản lý tài khoản AWS.

**Câu 4: ArgoCD đồng bộ dữ liệu theo mô hình nào?**
*   A. Push-based (Đẩy từ ngoài vào).
*   B. Pull-based (Tự kéo về từ bên trong).
*   C. Kết hợp cả hai.

**Câu 5: Nếu bạn bật tính năng `selfHeal: true` trên ArgoCD, điều gì xảy ra nếu ai đó dùng lệnh `kubectl delete deployment` thủ công?**
*   A. Hệ thống bị xóa hoàn toàn và không thể khôi phục.
*   B. ArgoCD phát hiện sự thiếu hụt và tự động tạo lại Deployment đó theo cấu hình trên Git.
*   C. ArgoCD sẽ báo động đỏ và gửi email yêu cầu admin phê duyệt.

*(Còn tiếp 10 câu trắc nghiệm tương tự để kiểm tra kiến thức tổng quát...)*

### 9.2. Phần câu hỏi tự luận phỏng vấn thực chiến (15 câu)

#### Câu 16: Em hãy phân biệt sự khác nhau giữa `git revert` và `git reset` trong quy trình khôi phục lỗi hạ tầng GitOps?
*   **Trả lời:** 
    *   `git revert` sẽ tạo ra một commit mới hoàn toàn mang nội dung đảo ngược của commit cũ chỉ định. Lịch sử Git sẽ đi thẳng tiến lên và không bị xóa bỏ. Cách này an toàn vì không làm hỏng lịch sử của nhóm làm việc chung và đúng tư tưởng GitOps.
    *   `git reset` sẽ xóa bỏ hoàn toàn lịch sử commit trở về trước. Nếu đã push lên server, bạn buộc phải dùng lệnh `git push --force` để ghi đè. Điều này cực kỳ nguy hiểm vì có thể ghi đè đứt gãy code của người khác và làm ArgoCD bị bối rối vì lịch sử Git bị sửa đổi đột ngột.

#### Câu 17: Tại sao chúng ta cần sử dụng Secrets của GitHub mà không viết trực tiếp mật khẩu vào file YAML của workflow?
*   **Trả lời:** Nếu ghi trực tiếp mật khẩu vào code, bất kỳ ai có quyền xem repo đều đọc được mật khẩu đó. Thậm chí nếu repo là public, các bot quét tự động trên Internet sẽ quét sạch key của bạn chỉ trong vòng vài giây và công ty sẽ phải trả hàng ngàn USD tiền tài nguyên AWS bị lạm dụng. GitHub Secrets mã hóa mật khẩu ở dạng một chiều và chỉ hiển thị giá trị dạng dấu sao `***` khi in log chạy pipeline.

#### Câu 18: Hãy giải thích cách hoạt động và cấu hình của App-of-Apps pattern trên ArgoCD? Khi nào nên dùng?
*   **Trả lời:** *Xem chi tiết tại Mục 5 của tài liệu.*

*(Còn tiếp 12 câu tự luận chuyên sâu khác...)*

---

## 10. Bài tập tự hành nâng cao (Hands-on Homework)

### Bài tập 1: Xây dựng pipeline kiểm tra chất lượng code tự động
1.  Viết một ứng dụng Node.js đơn giản với file `index.js` trả về dòng chữ "Hello World".
2.  Viết file test bằng thư mục Jest.
3.  Tạo workflow GitHub Actions chạy test mỗi khi có người sửa đổi code trong ứng dụng.

### Bài tập 2: Dựng hệ thống GitOps đồng bộ ứng dụng Nginx
1.  Cài đặt ArgoCD lên cụm K8s Minikube của bạn.
2.  Tạo một repo chứa file cấu hình Deployment chạy Nginx.
3.  Cấu hình Application trên ArgoCD liên kết tới repo đó.
4.  Tiến hành sửa file YAML trên Git (tăng số replicas lên 3) và chứng kiến sự thay đổi tự động diễn ra trên cụm Kubernetes của bạn.
