# Remote State trên S3 với `use_lockfile`

## 1. Vấn đề của State Local
Khi lưu trữ file `terraform.tfstate` cục bộ (local) trên máy cá nhân, hệ thống sẽ gặp phải 3 rủi ro lớn:
* **Không chia sẻ được:** Đồng nghiệp hoặc hệ thống CI/CD không có quyền truy cập vào file state cục bộ để triển khai hạ tầng chung.
* **Không an toàn:** File state chứa các thông tin nhạy cảm ở dạng plaintext (văn bản thô) nên dễ bị lộ lọt (đặc biệt khi lỡ commit lên Git).
* **Không chống ghi đè đồng thời:** Hai người cùng chạy `apply` tại một thời điểm có thể dẫn đến việc ghi đè đè lên nhau, làm hỏng và lệch pha trạng thái hạ tầng.

## 2. Giải pháp Remote State & Bài toán "Con gà - Quả trứng"
* **Remote State:** State được đưa lên một kho lưu trữ chung (như AWS S3) có mã hoá, phân quyền truy cập chặt chẽ và cơ chế khoá (Locking) khi thực thi.
* **Bài toán "Con gà - Quả trứng" (Bootstrap):** Để dùng S3 làm nơi lưu trữ State cho Terraform, bản thân S3 bucket phải tồn tại trước. Nhưng chúng ta lại muốn dùng chính Terraform để tạo S3 bucket đó.
* **Giải pháp:** Tách cấu hình làm 2 phần độc lập:
  1. **Thư mục bootstrap:** Cấu hình local để tạo S3 bucket lưu trữ state. Chạy một lần duy nhất, state của nó lưu local (vì cấu hình này rất ít khi thay đổi và dễ tái lập).
  2. **Thư mục ứng dụng (app):** Cấu hình chính thức và cấu hình backend trỏ vào S3 bucket vừa tạo từ bước 1.

### Cấu hình tối thiểu cho một S3 Bucket chứa State:
* **Versioning Enabled:** Giữ lại lịch sử mọi bản state cũ để khôi phục khi gặp sự cố ghi đè/lỗi.
* **Server-side Encryption (SSE-S3 hoặc KMS):** Tự động mã hoá file state khi lưu trữ trên S3.
* **Public Access Block:** Chặn hoàn toàn quyền truy cập public từ Internet để bảo vệ dữ liệu nhạy cảm.

## 3. Khai báo S3 Backend mới với `use_lockfile = true`
Từ các phiên bản Terraform mới (1.10 trở lên), bạn có thể bật tính năng khóa State trực tiếp trên S3 thông qua thuộc tính `use_lockfile = true` mà **không cần cấu hình thêm bảng DynamoDB** như trước đây.

```hcl
terraform {
  required_version = ">= 1.7"

  backend "s3" {
    bucket       = "tên-s3-bucket-bootstrap"
    key          = "app/terraform.tfstate" # Đường dẫn file state trên S3
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true                     # Sử dụng tính năng lock native trên S3 (DynamoDB is Deprecated)
  }
}
```

* **Lưu ý:** Block `backend` không cho phép sử dụng biến (variables) do nó được load và xử lý cực kỳ sớm trước cả khi biến được khai báo. Mọi thông tin cấu hình phải là chuỗi tĩnh (Hardcoded).

## 4. Cơ chế hoạt động của `use_lockfile`
* Khi một tiến trình ghi (như `plan`, `apply`, hoặc `destroy`) bắt đầu, Terraform sẽ gửi một yêu cầu ghi có điều kiện (conditional write) lên S3 để tạo một file khoá có tên dạng `<key>.tflock` (ví dụ `app/terraform.tfstate.tflock`).
* Nếu file khoá chưa tồn tại, S3 cho phép tạo, Terraform giữ file này và thực thi. Khi hoàn thành, file khoá sẽ bị tự động xóa.
* Nếu có một tiến trình khác đang chạy, file khoá đã tồn tại, yêu cầu ghi có điều kiện sẽ thất bại với mã lỗi **`StatusCode: 412 PreconditionFailed`**.
* Để gỡ khóa thủ công trong trường hợp tiến trình bị tắt đột ngột (crash) khiến file khóa bị kẹt, ta sử dụng lệnh:
  ```bash
  terraform force-unlock <LOCK_ID>
  ```
  *(Cảnh báo: Chỉ dùng khi chắc chắn không còn ai đang chạy lệnh apply).*
