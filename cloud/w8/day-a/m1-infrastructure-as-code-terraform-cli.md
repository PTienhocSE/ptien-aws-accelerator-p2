# Infrastructure as Code, Terraform Là Gì, và Làm Quen CLI

## 1. Vấn đề của cấu hình thủ công (Click-ops / Console-based Configuration)
Việc cấu hình hệ thống bằng cách thao tác trên giao diện Web (Console) hoặc gõ các câu lệnh rời rạc (`aws ec2 run-instances`) đem lại những rủi ro lớn khi hệ thống phát triển:
* **Không tái lập được (Non-reproducible):** Các bước thực hiện không được ghi chép, dẫn đến việc thiết lập môi trường mới (Staging/Production) hoặc khôi phục sau sự cố phụ thuộc hoàn toàn vào trí nhớ cá nhân.
* **Trôi dạt cấu hình (Configuration Drift):** Các chỉnh sửa "nóng" trực tiếp trong quá trình vận hành mà không đồng bộ ngược lại sẽ làm hệ thống thực tế khác biệt so với thiết kế ban đầu.
* **Thiếu quy trình kiểm duyệt (No Code Review):** Các thao tác thay đổi hạ tầng nguy hiểm (mở cổng bảo mật, xóa tài nguyên hệ thống) không thể review bằng mã nguồn (no code diff, no PR).

## 2. Giải pháp: Infrastructure as Code (IaC)
IaC định nghĩa toàn bộ tài nguyên mong muốn bằng các file cấu hình tĩnh được lưu trữ trong Git:
* **Source of Truth:** Mã nguồn là nguồn chân lý duy nhất mô tả hạ tầng.
* **Tính nhất quán:** Dễ dàng phát hiện Drift bằng cách đối chiếu mã nguồn và thực tế.
* **Quy trình chuẩn hóa:** Áp dụng quy trình kiểm duyệt code (Pull Request, Code Review) lên hạ tầng trước khi triển khai.

## 3. Terraform là gì?
Terraform là công cụ IaC nguồn mở được phát triển bởi HashiCorp dùng để định nghĩa tài nguyên trên cloud và on-prem.
* **Khai báo (Declarative):** Trái ngược với lập trình thủ tục (Imperative), người dùng chỉ khai báo **Trạng thái mong muốn** (Desired State) của hạ tầng. Terraform sẽ tự động phân tích đồ thị phụ thuộc và đưa ra các hành động cần thiết (Tạo mới, Cập nhật, Hủy bỏ) để đạt được trạng thái đó.

### Ba khái niệm cốt lõi:
1. **Provider:** Plugin cầu nối giao tiếp giữa Terraform Core và API của từng dịch vụ cụ thể (AWS, GCP, Kubernetes, Cloudflare,...). Các plugin này được lưu ở thư mục local `.terraform/` sau khi khởi tạo.
2. **Resource:** Đơn vị hạ tầng cơ bản được quản lý (ví dụ: `aws_instance`, `aws_s3_bucket`).
3. **State:** Cuốn sổ ghi chép trạng thái thực tế (`terraform.tfstate`) dùng để đối chiếu cấu hình với môi trường thực tế.

## 4. Kiến trúc hoạt động của Terraform
Terraform chạy dưới dạng hai tiến trình riêng biệt giao tiếp qua **gRPC (local)**:

```text
               terraform plan / apply
                         │
          ┌──────────────▼───────────────┐
          │       Terraform Core          │ (Đọc file .tf & state, dựng đồ thị
          │                              │  phụ thuộc, tính toán kế hoạch)
          └──────────────┬───────────────┘
                         │ gRPC (local protocol)
          ┌──────────────▼───────────────┐
          │       Provider Plugin         │ (Cung cấp schema cấu hình, dịch yêu
          │       (e.g. AWS Provider)    │  cầu thành lệnh gọi API thật qua SDK)
          └──────────────┬───────────────┘
                         │ HTTPS (AWS API calls)
          ┌──────────────▼───────────────┐
          │           AWS API            │ (Tài nguyên vật lý trên cloud)
          └──────────────────────────────┘
```

* **Terraform Core:** Tổng hợp và phân tích code `.tf`, xây dựng biểu đồ tài nguyên (Resource Graph), tính toán phần khác biệt (diff) so với State hiện tại để đưa ra kế hoạch. Core hoàn toàn độc lập và không chứa mã nguồn gọi API Cloud.
* **Provider:** Chứa logic nghiệp vụ của cloud tương ứng. Provider dịch các yêu cầu tạo/sửa/xóa từ Core thành lệnh API thực tế của dịch vụ đám mây đó (ví dụ: gọi qua SDK).

## 5. Giấy phép sử dụng (License)
* Từ phiên bản **1.6** (08/2023), Terraform chuyển sang giấy phép **BUSL 1.1** (Business Source License).
* Giấy phép này vẫn hoàn toàn miễn phí cho cá nhân và doanh nghiệp sử dụng nội bộ để quản lý hạ tầng của chính mình. Nó chỉ hạn chế việc đóng gói Terraform để cung cấp dịch vụ thương mại cạnh tranh trực tiếp với HashiCorp.
* Điều này dẫn đến sự ra đời của **OpenTofu** (bản fork mã nguồn mở dưới giấy phép MPL 2.0).

## 6. Vòng đời Terraform & CLI cơ bản
Quy trình làm việc chuẩn hằng ngày xoay quanh 4 bước:
1. **Write:** Viết khai báo tài nguyên trong `.tf`.
2. **Plan (`terraform plan`):** Tạo bản xem trước kế hoạch thay đổi (dry-run).
3. **Apply (`terraform apply`):** Thực thi kế hoạch lên hệ thống thực tế và lưu ID tài nguyên vào `state`.
4. **Destroy (`terraform destroy`):** Xóa toàn bộ hạ tầng đã tạo.

### Các lệnh CLI thông dụng:
* `terraform init`: Cấu hình backend, tải provider plugins về `.terraform/`.
* `terraform validate`: Kiểm tra cú pháp và tính logic của cấu hình tĩnh.
* `terraform fmt`: Định dạng lại file code `.tf` chuẩn hóa theo HCL.
* `terraform console`: Môi trường tương tác dòng lệnh để test các biểu thức HCL.
* `terraform show`: Xem chi tiết trạng thái state hoặc kế hoạch plan đang lưu trữ.
