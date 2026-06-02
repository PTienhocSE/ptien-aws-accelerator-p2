# Variable, Output, Locals và Kiểm Tra Giá Trị Sớm

## 1. Variable (Biến đầu vào của cấu hình)
* **Khái niệm:** Dùng để đưa các tham số từ bên ngoài vào cấu hình Terraform, giúp mã nguồn linh hoạt và dễ tái sử dụng cho nhiều môi trường (dev, staging, prod) mà không cần chỉnh sửa trực tiếp mã nguồn.
* **Khai báo mẫu:**
  ```hcl
  variable "environment" {
    type        = string
    description = "Môi trường triển khai: dev | staging | prod"
    default     = "dev"
  }
  ```
  * `type`: Kiểu dữ liệu bắt buộc (string, number, bool, list, map, object...).
  * `default`: Giá trị mặc định. Nếu không khai báo default, biến trở thành bắt buộc nhập khi chạy lệnh.
* **Thứ tự ưu tiên nạp biến (Từ thấp đến cao):**
  1. Giá trị mặc định (`default`).
  2. Biến môi trường hệ thống (Ví dụ: `TF_VAR_environment=prod`).
  3. File chứa giá trị biến tự động nạp `terraform.tfvars` hoặc `*.auto.tfvars`.
  4. Cờ dòng lệnh trực tiếp (Ví dụ: `-var environment=prod`) $\rightarrow$ Ưu tiên cao nhất.

## 2. Output (Đầu ra của cấu hình)
* **Mục đích:** Công bố hoặc xuất ra các giá trị thuộc tính tài nguyên sau khi apply thành công. Dùng để người chạy quan sát hoặc làm thông tin đầu vào cho các cấu hình Terraform khác (thông qua remote state).
* **Khai báo mẫu:**
  ```hcl
  output "bucket_name" {
    value     = aws_s3_bucket.app.id
    sensitive = true # Che giấu thông tin nhạy cảm ở màn hình console
  }
  ```

## 3. Locals (Biến cục bộ bên trong cấu hình)
* **Mục đích:** Gán một cái tên định danh đại diện cho một biểu thức tính toán hoặc một bộ cấu hình phức tạp để tái sử dụng nhiều nơi trong file, tránh lặp code (DRY - Don't Repeat Yourself).
* **Khai báo mẫu:**
  ```hcl
  locals {
    name_prefix = "${var.project}-${var.environment}"
    common_tags = {
      Project     = var.project
      Environment = var.environment
    }
  }
  ```
* **Phân biệt Variable và Locals:**
  * **Variable:** Nhận giá trị truyền vào từ **bên ngoài** cấu hình.
  * **Locals:** Tính toán và xử lý logic nội bộ **bên trong** cấu hình (thường dựa trên việc ghép/tính toán từ các Variable khác).
  * *Lưu ý:* Tránh lạm dụng locals quá mức vì có thể che mất nguồn gốc xuất xứ thực sự của dữ liệu, khiến mã nguồn khó đọc.

## 4. Chặn dữ liệu sai sớm: Block `validation`
* **Mục đích:** Chặn và dừng ngay lập tức các giá trị nhập sai cho biến ở bước `plan`, trước khi thực thi hoặc gọi API lên Cloud Provider.
* **Khai báo mẫu:**
  ```hcl
  variable "environment" {
    type = string
    validation {
      condition     = contains(["dev", "staging", "prod"], var.environment)
      error_message = "Môi trường environment bắt buộc phải là một trong: dev, staging hoặc prod."
    }
  }
  ```
* Nếu truyền sai (ví dụ `-var environment=production`), Terraform báo lỗi ngay ở bước lập kế hoạch và in ra thông điệp thiết lập sẵn tại `error_message`.

## 5. Rào chắn logic tài nguyên: `precondition` và `postcondition`
Đặt bên trong block `lifecycle` của từng resource để kiểm tra các mối quan hệ logic phức tạp giữa các tài nguyên hoặc điều kiện nghiệp vụ:

### Precondition (Điều kiện tiên quyết)
* Chạy sau bước plan nhưng **trước khi tạo tài nguyên**.
* Kiểm tra các giả định đầu vào của tài nguyên đó (không thể tham chiếu thuộc tính của chính tài nguyên này vì nó chưa được tạo).
* **Ví dụ:** Cấm bật `force_destroy` ở môi trường sản xuất (prod):
  ```hcl
  resource "aws_s3_bucket" "app" {
    # ...
    lifecycle {
      precondition {
        condition     = !local.is_production || !var.force_destroy
        error_message = "Cảnh báo: Không được bật force_destroy đối với môi trường Product."
      }
    }
  }
  ```

### Postcondition (Điều kiện sau thực thi)
* Chạy **sau khi tài nguyên đã được tạo hoặc truy vấn xong**.
* Kiểm tra các giá trị thực tế trả về từ Cloud Provider xem có thỏa mãn điều kiện hay không (Có thể sử dụng thuộc tính `self` để kiểm tra chính nó).
* **Ví dụ:** Đảm bảo instance EC2 sau khi tạo nằm đúng trong VPC mong muốn.

### Block `check` (Cảnh báo không chặn)
* Chạy ngoài vòng đời thông thường để giám sát điều kiện liên tục, chỉ đưa ra cảnh báo (warning) chứ không làm lỗi hay dừng quá trình apply.

```text
  [Nhập biến]         [Plan xong]           [Apply]            [Apply xong]
  ───────────         ───────────         ───────────          ────────────
  validation   ──►    precondition   ──►  Tạo/Sửa Resource ──► postcondition
 (Kiểm tra biến)     (Kiểm tra logic)                          (Kiểm tra kết quả)
```
