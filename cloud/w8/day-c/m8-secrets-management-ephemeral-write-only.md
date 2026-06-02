# Secrets: sensitive, ephemeral, và Write-Only Arguments

## 1. Giới hạn của tham số `sensitive = true`
* **Cách hoạt động:** Khi đánh dấu một variable hoặc output là `sensitive = true`, Terraform sẽ ẩn đi (che chắn) giá trị này khi xuất kết quả ra giao diện dòng lệnh CLI (terminal) nhằm tránh tình trạng bị lộ khi người khác nhìn qua vai.
* **Đặc tính lan truyền:** Bất kỳ giá trị nào được dẫn xuất từ biến sensitive (ví dụ: ghép chuỗi kết nối chứa mật khẩu, hoặc sử dụng hàm tính độ dài) cũng sẽ tự động được coi là sensitive.
* **GIỚI HẠN CHÍ MẠNG:** Tham số `sensitive = true` **không hề mã hóa hay ẩn thông tin trong file State**. Giá trị nhạy cảm vẫn được ghi dưới dạng văn bản thô (Plaintext) trực tiếp trong file `terraform.tfstate`. Do đó, đây không phải là giải pháp bảo vệ dữ liệu ở tầng lưu trữ.

## 2. Ephemeral Resources (Tài nguyên tạm thời)
* Tính năng được ra mắt từ **Terraform 1.10**.
* **Đặc điểm:** Ephemeral resource (khai báo bằng block `ephemeral` thay vì `resource`) chỉ được Terraform truy vấn và sử dụng tạm thời ngay trong thời gian thực thi (khi chạy plan/apply) để lấy các giá trị nhạy cảm (như API key, mật khẩu từ HashiCorp Vault hoặc AWS Secrets Manager) **và tuyệt đối không lưu lại dữ liệu này vào file State hay Plan**.
* **Cú pháp mẫu:**
  ```hcl
  ephemeral "aws_secretsmanager_secret_version" "db" {
    secret_id = "my-db-secret"
  }
  ```

## 3. Write-Only Arguments (Tham số chỉ ghi)
* Tính năng được ra mắt từ **Terraform 1.11**.
* **Đặc điểm:** Cho phép gửi giá trị cấu hình nhạy cảm từ Terraform sang Cloud Provider (thông qua Provider Plugin), sau đó Terraform sẽ **ngay lập tức xóa bỏ giá trị đó khỏi bộ nhớ mà không ghi lại vào file State hay Plan**.
* **Quy ước đặt tên:** Các tham số chỉ ghi có hậu tố `_wo` (ví dụ `secret_string_wo`, `password_wo`) và luôn đi kèm một tham số kiểm soát phiên bản `_wo_version` (ví dụ `secret_string_wo_version`).
* **Cơ chế hoạt động:** Terraform chỉ lưu giá trị phiên bản `_wo_version` trong file State để biết khi nào cần cập nhật lại secret mới (khi giá trị version tăng lên). Bản thân secret thực tế đã được áp dụng lên Cloud nhưng State của Terraform vẫn hoàn toàn sạch sẽ (giá trị lưu là `null`).

## 4. Chứng minh thực tế: Trường hợp `secret_string` vs `secret_string_wo`
Khi tạo 2 phiên bản secret bằng AWS Secrets Manager:

```hcl
# CÁCH CŨ: Giá trị mật khẩu lọt vào state dưới dạng plaintext
resource "aws_secretsmanager_secret_version" "legacy" {
  secret_id     = aws_secretsmanager_secret.legacy.id
  secret_string = "p@ssw0rd-demo"
}

# CÁCH MỚI: Dữ liệu gửi đi AWS thành công nhưng State vẫn sạch
resource "aws_secretsmanager_secret_version" "wo" {
  secret_id                = aws_secretsmanager_secret.wo.id
  secret_string_wo         = "p@ssw0rd-demo"
  secret_string_wo_version = 1
}
```

* **Kết quả trong file State:**
  * Tại `legacy`: Thuộc tính `secret_string` hiển thị rõ ràng `"p@ssw0rd-demo"`.
  * Tại `wo`: Thuộc tính `secret_string` và `secret_string_wo` đều trả về `null`.
* **Kết quả trên AWS:** Cả hai đều được tạo thành công với mật khẩu chính xác trên AWS Secrets Manager.

## 5. Quy tắc thực hành quản lý Secret tốt nhất
1. Không hardcode mật khẩu trực tiếp trong file `.tf`.
2. Kết hợp **Ephemeral Resources** (Đọc thông tin nhạy cảm từ Vault/Secrets Manager mà không lưu vào State) cùng với **Write-Only Arguments** (Đẩy thông tin cấu hình nhạy cảm lên Cloud mà không lưu lại trong State).
3. Quy trình này tạo ra một đường truyền khép kín hoàn toàn sạch cho dữ liệu nhạy cảm từ nguồn cấp đến đích, bảo vệ file State khỏi các rủi ro lộ lọt secret.
