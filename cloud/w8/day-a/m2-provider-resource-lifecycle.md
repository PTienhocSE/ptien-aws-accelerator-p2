# Provider, Resource Đầu Tiên, và Vòng Đời init plan apply destroy

## 1. Cấu trúc cấu hình cơ bản & Pin phiên bản (Versioning)
Một cấu hình Terraform tiêu chuẩn bắt đầu bằng việc khai báo provider và ràng buộc phiên bản trong block `terraform`:

```hcl
terraform {
  required_version = ">= 1.7" # Ràng buộc phiên bản Terraform Core

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Nguồn tải provider từ Registry
      version = "~> 6.0"        # Toán tử pessimistic constraint
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
```

* **Ràng buộc phiên bản Core (`required_version`):** Ngăn chặn việc chạy cấu hình bằng các phiên bản Terraform quá cũ hoặc quá mới chưa tương thích.
* **Toán tử pessimistic constraint (`~> 6.0`):** Cho phép tự động tải các bản vá lỗi và tính năng nhỏ (minor/patch) thuộc dòng `6.x` (ví dụ `6.46.0`), nhưng chặn không tự động nâng cấp lên phiên bản major `7.0` (tránh rủi ro thay đổi cú pháp gây vỡ hệ thống).
* **Credential:** Không hardcode credential vào code. AWS Provider tự động tìm thông tin xác thực theo thứ tự ưu tiên: biến môi trường (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), file cấu hình AWS CLI local (`~/.aws/credentials`), hoặc IAM Instance Profiles.

## 2. Lệnh `terraform init` và Cơ chế Khóa (Lock File)
Khi chạy `terraform init`:
1. Đọc phần cấu hình `required_providers`.
2. Tải binary của provider tương ứng (ví dụ `hashicorp/aws v6.46.0`) về thư mục `.terraform/`.
3. Tạo ra file khóa **`.terraform.lock.hcl`**.

### Lock File `.terraform.lock.hcl` là gì?
* Ghi lại chính xác phiên bản provider đã tải và mã checksum của nó.
* **Vai trò:** Hoạt động giống như `package-lock.json` của npm. Giúp đảm bảo tất cả thành viên trong đội ngũ phát triển và hệ thống CI/CD sử dụng chung một phiên bản provider nhất định.
* **Quy tắc Git:** **NÊN** commit file `.terraform.lock.hcl` vào Git, nhưng **KHÔNG ĐƯỢC** commit thư mục `.terraform/`.

## 3. Khai báo Resource và Đọc Plan
Mỗi block resource được khai báo với 2 nhãn:
* **Kiểu tài nguyên (Type):** Được quy định bởi Provider (ví dụ: `aws_s3_bucket`).
* **Tên cục bộ (Local Name):** Tên tham chiếu nội bộ trong code Terraform (ví dụ: `first`). Tên này không hiển thị trên AWS.

```hcl
resource "aws_s3_bucket" "first" {
  bucket_prefix = "tf-series-bai2-" # AWS tự động thêm hậu tố ngẫu nhiên để tránh trùng tên toàn cầu
  force_destroy = true              # Cho phép xóa bucket kể cả khi còn chứa dữ liệu bên trong (Lab only)
}
```

### Các trạng thái trong `terraform plan`:
* Ký hiệu **`+`**: Tài nguyên sẽ được tạo mới.
* Ký hiệu **`~`**: Tài nguyên sẽ được cập nhật/thay đổi.
* Ký hiệu **`-`**: Tài nguyên sẽ bị xóa bỏ.
* **`(known after apply)`:** Các thuộc tính do Cloud Provider tự động sinh ra sau khi tạo thành công tài nguyên (ví dụ: ARN, ID, Domain Name) và không thể biết trước khi chạy `apply`.

## 4. File trạng thái (State File - `terraform.tfstate`)
* **Khái niệm:** Là file JSON lưu trữ ánh xạ giữa code Terraform với tài nguyên thực tế trên Cloud.
* **Bản chất:** Chứa toàn bộ siêu dữ liệu bao gồm cả các thông tin nhạy cảm ở dạng plain text (như mật khẩu cơ sở dữ liệu, private key).
* **Quy tắc Git:** **TUYỆT ĐỐI KHÔNG** commit file `terraform.tfstate` hoặc `terraform.tfstate.backup` lên Git. Trong môi trường thực tế, file này cần được lưu trữ an toàn ở các Backend từ xa (Remote State trên S3, Terraform Cloud) kèm cơ chế mã hóa và khóa state.

## 5. Tính chất lũy đẳng (Idempotence)
* **Khái niệm:** Dù chạy lệnh `terraform apply` bao nhiêu lần với cùng một file cấu hình thì kết quả hạ tầng nhận được vẫn hoàn toàn giống nhau.
* **Cơ chế so sánh 3 chiều (Three-Way Comparison):** Trước khi tính toán plan, Terraform sẽ thực hiện "Refresh" bằng cách:
  1. Đọc ID tài nguyên trong file `state`.
  2. Gọi API của Cloud Provider để truy vấn trạng thái thực tế của tài nguyên đó.
  3. So sánh 3 yếu tố: **Cấu hình mong muốn (Code)** $\leftrightarrow$ **Trạng thái ghi nhận cuối (State)** $\leftrightarrow$ **Trạng thái thực tế (Cloud API)**.
  4. Nếu cả 3 khớp nhau, Terraform báo `No changes` (Không có thay đổi).

## 6. Lệnh dọn dẹp `terraform destroy`
* Lệnh `terraform destroy` đọc file `state` để biết những tài nguyên nào đang được quản lý, tiến hành gọi API để xóa chúng và cập nhật lại file state về trạng thái rỗng.
* Luôn chạy lệnh này sau khi hoàn thành thực hành/lab để tránh phát sinh chi phí ngoài ý muốn.
