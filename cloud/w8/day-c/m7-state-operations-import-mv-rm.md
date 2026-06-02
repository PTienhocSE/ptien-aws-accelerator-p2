# Thao Tác State: `import` Block, `state mv`, và `state rm`

## 1. Nhu cầu thao tác trực tiếp lên State
Trong quá trình vận hành thực tế, chúng ta thường xuyên gặp các bài toán không thể xử lý bằng cách viết code `.tf` và chạy `apply` thông thường. Có 3 nhu cầu phổ biến:
1. **Import:** Nhận quyền quản lý các tài nguyên đã được tạo thủ công (bằng click-ops) từ trước đó mà không làm ảnh hưởng tới hoạt động của chúng.
2. **Move (`state mv`):** Đổi tên tài nguyên trong code hoặc gom tài nguyên vào một module mà không muốn Terraform phá hủy rồi tạo lại.
3. **Remove (`state rm`):** Ngừng quản lý một tài nguyên nhưng vẫn muốn giữ nguyên tài nguyên đó chạy bình thường trên Cloud.

## 2. Config-Driven Import (`import` block) và Tự động sinh code
Kể từ phiên bản **Terraform 1.5**, quy trình import đã được chuẩn hóa thông qua khai báo (Config-driven import) thay vì chạy câu lệnh CLI thủ công lỗi thời (`terraform import`).

### Cấu trúc block `import`:
```hcl
import {
  to = aws_s3_bucket.adopted                       # Địa chỉ local mong muốn đặt trong code
  id = "tf-series-bai7-preexisting-1779678443"    # ID hoặc tên thực tế của tài nguyên trên Cloud
}
```

### Cách tự động sinh mã nguồn cấu hình (`-generate-config-out`):
Nếu chỉ khai báo block `import` mà chưa viết code resource tương ứng, bạn có thể yêu cầu Terraform tự động sinh code nháp bằng lệnh:
```bash
terraform plan -generate-config-out=generated.tf
```
* **Kết quả:** Terraform sẽ tự động tạo file `generated.tf` chứa toàn bộ các thuộc tính thực tế của tài nguyên đó.
* **Thao tác tiếp theo:** Review lại file sinh tự động, dọn dẹp các tham số mặc định không cần thiết, chuyển mã này vào file cấu hình chính (ví dụ `main.tf`) rồi tiến hành chạy lệnh:
  ```bash
  terraform apply
  ```
  *(Kết quả in ra sẽ là: `1 imported, 0 added, 0 changed, 0 destroyed`)*

## 3. Di chuyển/Đổi tên tài nguyên (`terraform state mv`)
* **Mục đích:** Khi bạn đổi tên một block resource trong code (ví dụ đổi `resource "aws_s3_bucket" "adopted"` thành `"data"`), nếu không thao tác state, Terraform sẽ xóa bucket cũ và tạo bucket mới (làm mất toàn bộ dữ liệu).
* **Cách giải quyết:** Sử dụng lệnh `state mv` để cập nhật lại ánh xạ lưu trong file state trước khi apply:
  ```bash
  terraform state mv aws_s3_bucket.adopted aws_s3_bucket.data
  ```
* **Lưu ý:** Lệnh này chỉ sửa đổi file state, bạn cần phải đồng thời đổi tên tương ứng trong file code cấu hình `.tf` cho đồng nhất.

## 4. Ngừng quản lý tài nguyên (`terraform state rm`)
* **Mục đích:** Ngừng đưa tài nguyên vào tầm kiểm soát của Terraform nhưng không phá hủy tài nguyên thực tế trên Cloud (cắt đứt liên kết quản lý). Thường dùng khi muốn chuyển giao tài nguyên đó sang một dự án Terraform khác quản lý.
* **Cách thực hiện:**
  ```bash
  terraform state rm aws_s3_bucket.data
  ```
* **Hậu quả:** Tài nguyên đó sẽ trở thành "tài nguyên mồ côi" (orphaned resource). Lệnh `terraform destroy` sẽ không thể tìm thấy để xóa tài nguyên này. Bạn phải tự chịu trách nhiệm quản lý hoặc xóa nó bằng tay trên Cloud (nhằm tránh phát sinh chi phí ngầm).

## 5. Tổng kết quy tắc thao tác State an toàn
* Luôn đảm bảo cơ chế Remote State đã bật tính năng **Versioning** trên S3 (để khôi phục lại khi thao tác sai làm hỏng state).
* Đảm bảo tính năng **Locking** hoạt động bình thường để tránh tranh chấp ghi đè state trong lúc đang chạy lệnh chuyển đổi.
* Trong các phiên bản Terraform mới (1.8+), bạn cũng có thể khai báo việc di chuyển bằng block `moved {}` và xóa bằng block `removed {}` trực tiếp bằng code thay vì chạy lệnh CLI tay.
