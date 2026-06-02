# State: Terraform Lưu Gì, Vì Sao Cần, và Drift

## 1. Vì sao Terraform cần file State?
Nhiều người thắc mắc vì sao Terraform cần một file trạng thái riêng biệt (`terraform.tfstate`) thay vì truy vấn trực tiếp Cloud Provider (như AWS API) mỗi lần chạy. HashiCorp đưa ra 4 lý do chính:

1. **Ánh xạ tài nguyên cấu hình với thực tế (Mapping):**
   * Trong file `.tf`, bạn đặt tên cục bộ là `aws_s3_bucket.demo`, nhưng trên AWS nó được định danh bằng một ID ngẫu nhiên (ví dụ: `tf-series-bai4-2026...`).
   * State lưu giữ mối liên kết này để Terraform biết khi bạn chỉnh sửa block code `demo` thì cần gọi API tác động vào tài nguyên nào trên AWS.
2. **Metadata về mối quan hệ phụ thuộc (Metadata & Dependency Tracking):**
   * State ghi nhớ mối liên kết giữa các tài nguyên. Khi bạn xóa một tài nguyên khỏi code cấu hình, Terraform dựa vào thông tin lưu sẵn trong State để xác định thứ tự phá hủy tài nguyên hợp lý (ví dụ: không xóa Subnet trước khi xóa Instance đang nằm trong Subnet đó).
3. **Tối ưu hiệu năng (Performance Cache):**
   * Với hạ tầng lớn có hàng trăm tài nguyên, việc gọi API Cloud để kiểm tra thuộc tính từng tài nguyên mỗi lần chạy `plan` sẽ cực kỳ chậm do độ trễ mạng và giới hạn tần suất gọi API (Rate Limiting). State đóng vai trò như một bản cache giúp tính toán kế hoạch nhanh chóng.
4. **Đồng bộ hóa nhóm làm việc (Team Sync & Collaboration):**
   * Lưu State ở một nơi dùng chung (Remote State) đảm bảo mọi thành viên và hệ thống CI/CD đều làm việc trên cùng một phiên bản hạ tầng, tránh ghi đè chéo cấu hình lên nhau thông qua cơ chế khóa State (State Locking).

## 2. File State lưu trữ những gì?
Để xem danh sách tài nguyên và thông tin chi tiết được lưu trong State mà không cần đọc trực tiếp file JSON thô, Terraform cung cấp các lệnh sau:
* **`terraform state list`**: Liệt kê tất cả tài nguyên đang được quản lý bởi cấu hình hiện tại.
* **`terraform state show <resource_address>`**: Hiển thị chi tiết tất cả thuộc tính của một tài nguyên cụ thể đang được cache trong State.

## 3. Cơ chế So sánh 3 Chiều (Three-Way Comparison) & Refresh
Mỗi lần thực thi lệnh `plan` hoặc `apply`, Terraform thực hiện quy trình so sánh 3 chiều:

```text
   main.tf                  terraform.tfstate                Cloud API
(Cấu hình mong muốn)       (Lần cuối đã biết)              (Hạ tầng thực tế)
       │                           │                              │
       └─────────────┬─────────────┴──────────────┬───────────────┘
                     ▼                            ▼
              [Refresh]: Truy vấn thực tế và cập nhật bản cache
                     │
                     ▼
              [So sánh]: Đưa ra khác biệt (diff) -> Kế hoạch (Plan)
```

1. **Refresh:** Tìm kiếm các ID tài nguyên trong file `state`, truy vấn trực tiếp API Cloud để cập nhật lại thông tin mới nhất vào bộ nhớ tạm thời.
2. **So sánh (Diff):** Đối chiếu giữa cấu hình mong muốn trong mã nguồn `.tf` với thực tế đã cập nhật từ bước Refresh để sinh ra Plan hành động thích hợp.

## 4. Hiện tượng trôi dạt cấu hình (Drift)
* **Khái niệm:** Drift xảy ra khi tài nguyên thực tế bị thay đổi bên ngoài tầm kiểm soát của Terraform (ví dụ: thao tác bằng tay trên giao diện web Console, hoặc chạy lệnh CLI trực tiếp).
* **Hành vi của Terraform:** Khi phát hiện có sự sai lệch giữa thực tế và file cấu hình, mặc định lệnh `terraform plan` thông thường sẽ coi **mã cấu hình `.tf` là chuẩn mực duy nhất** và đề xuất hành động chỉnh sửa hạ tầng thật để đưa nó về đúng thiết kế ban đầu.
  * Ký hiệu `~` thể hiện sự cập nhật tại chỗ (update in-place).
  * Ví dụ: Nếu cấu hình định nghĩa `Env = "dev"` nhưng thực tế bị đổi thành `Env = "production"`, Terraform sẽ báo kế hoạch thay đổi ngược lại: `"production" -> "dev"`.

## 5. Hai lựa chọn xử lý khi có Drift
Khi có sự thay đổi hạ tầng ngoài ý muốn và bạn phát hiện ra nó, bạn có 2 cách giải quyết:
1. **Dùng Plan thông thường (Kéo thực tế về cấu hình):** Chạy `terraform apply` để ghi đè và sửa đổi hạ tầng thật trên Cloud về đúng giá trị viết trong file cấu hình `.tf`.
2. **Dùng chế độ Refresh-only (Đồng bộ cấu hình & State theo thực tế):**
   * Sử dụng lệnh: `terraform plan -refresh-only` (hoặc `terraform apply -refresh-only`).
   * Chế độ này coi **thực tế trên Cloud là chuẩn mực**, nó sẽ ghi đè giá trị thực tế mới nhất vào file State mà không làm thay đổi tài nguyên trên Cloud (ví dụ: cập nhật State từ `"dev" -> "production"`).
   * *Lưu ý:* Sau khi apply refresh-only, bạn cần tự tay sửa lại code trong file `.tf` cho khớp với thực tế để tránh báo Drift ở các lần plan tiếp theo.

## 6. Lưu ý bảo mật: State là Plaintext
* File `terraform.tfstate` lưu trữ toàn bộ các thuộc tính của tài nguyên ở dạng văn bản thô (Plaintext).
* Điều này đồng nghĩa với việc các thông tin nhạy cảm như: mật khẩu cơ sở dữ liệu, khoá bảo mật (Private Key), Token API... đều hiển thị công khai trong file này.
* **Quy tắc an toàn tuyệt đối:**
  * **Không bao giờ** commit các file `terraform.tfstate` hoặc `terraform.tfstate.backup` lên Git.
  * Phải sử dụng giải pháp lưu trữ **Remote State** (như AWS S3, HashiCorp Cloud Platform) có hỗ trợ mã hóa ở trạng thái nghỉ (encryption at rest) và phân quyền chặt chẽ (IAM/Access Control).
