# HCL Từ Trong Ra Ngoài: Block, Kiểu Dữ Liệu, Biểu Thức

## 1. Ba thành phần cơ bản của cú pháp HCL
Ngôn ngữ HCL (HashiCorp Configuration Language) được xây dựng dựa trên hai thành phần cơ bản: **Argument** và **Block**.

### Argument (Đối số)
* Dùng để gán một giá trị cho một tên định danh: `region = "ap-southeast-1"`.
* Bên trái dấu `=` là **Identifier** (tên định danh), bên phải là một **Expression** (biểu thức).

### Block (Khối)
* Là vùng chứa các dữ liệu và cấu hình khác.
* Cấu trúc gồm: **Type** (Kiểu block), các **Label** (Nhãn định danh), và **Body** (Thân block nằm trong dấu ngoặc nhọn `{}`).
* Ví dụ:
  ```text
  resource  "aws_s3_bucket"  "first"  {
     │           │              │      └── body (thân block)
     │           │              └───────── label 2: tên local
     │           └──────────────────────── label 1: kiểu resource
     └──────────────────────────────────── type: loại block

      bucket_prefix = "tf-series-bai2-"
      └── identifier ┘ └─ biểu thức ─┘
      └──────────── argument ────────────┘

      tags = {                # giá trị kiểu map
        Project = "terraform-series"
      }
  }
  ```
* Số lượng label phụ thuộc vào kiểu block (ví dụ: `resource` cần 2 labels, `provider` cần 1 label, `terraform` không cần label nào).

### Quy định về Identifier & Comment:
* **Identifier:** Chỉ gồm chữ cái, chữ số, dấu gạch dưới `_`, gạch nối `-`, và **không** được bắt đầu bằng chữ số.
* **Comment:**
  * `#`: Một dòng (Khuyến nghị sử dụng chuẩn).
  * `//`: Một dòng (khi chạy `terraform fmt` sẽ tự chuyển thành `#`).
  * `/* ... */`: Nhiều dòng.

## 2. Công cụ thử nghiệm `terraform console`
* `terraform console` cung cấp một giao diện tương tác (REPL prompt) để kiểm tra cú pháp, hàm và biểu thức HCL ngay lập tức mà không cần tạo hay thay đổi hạ tầng.
* Cách dùng nhanh qua command line:
  ```bash
  echo 'upper("hello")' | terraform console
  # Kết quả: "HELLO"
  ```

## 3. Sáu kiểu giá trị trong Terraform
### Ba kiểu nguyên thủy (Primitive):
1. **string:** Chuỗi ký tự Unicode đặt trong ngoặc kép `"..."`.
2. **number:** Giá trị số (bao gồm cả số nguyên `15` và số thực `6.28`).
3. **bool:** Giá trị logic (`true` hoặc `false`).

### Hai kiểu cấu trúc (Collection/Structural):
4. **list / tuple:** Dãy giá trị có thứ tự, đánh số từ `0`.
   * *List:* Yêu cầu mọi phần tử phải cùng kiểu dữ liệu.
   * *Tuple:* Cho phép các phần tử có kiểu dữ liệu khác nhau.
5. **map / object:** Nhóm cặp khóa-giá trị (Key-Value).
   * *Map:* Các giá trị (Value) của các khóa phải cùng một kiểu dữ liệu.
   * *Object:* Cho phép mỗi khóa có một kiểu dữ liệu riêng biệt.

### Kiểu đặc biệt:
6. **null:** Đại diện cho sự vắng mặt hoặc bỏ qua một thuộc tính. Khi một argument nhận giá trị `null`, Terraform coi như argument đó không được khai báo và sẽ áp dụng giá trị mặc định (nếu có).

## 4. Biểu thức (Expressions) & Hàm dựng sẵn (Built-in Functions)
* **Toán tử ba ngôi (Ternary Operator):** `điều_kiện ? giá_trị_nếu_đúng : giá_trị_nếu_sai`. Rất hữu ích để bật/tắt tài nguyên tùy theo môi trường (ví dụ: `var.env == "prod" ? 3 : 1`).
* **Nội suy chuỗi (String Interpolation):** Chèn biểu thức vào chuỗi thông qua cú pháp `${...}` (ví dụ: `"${var.env}-web-server"`).
* **Hàm dựng sẵn (Built-in Functions):** Terraform cung cấp sẵn hàng trăm hàm xử lý logic (xử lý chuỗi, toán học, collection, IP mạng,...). Người dùng không thể tự định nghĩa hàm riêng.
  * `length(list)`: Đếm số lượng phần tử.
  * `tostring(value)`: Ép kiểu sang string.
  * `cidrsubnet(prefix, newbits, netnum)`: Tính toán và chia subnet tự động từ một dải CIDR ban đầu.

## 5. Block đặc biệt `terraform {}`
Block này dùng để cấu hình thiết lập tĩnh cho chính môi trường chạy Terraform và không được phép sử dụng biến (variables). Nó chứa 6 thành phần chính:
1. `required_version`: Định nghĩa phiên bản Terraform CLI cho phép chạy code.
2. `required_providers`: Khai báo nguồn và phiên bản các provider plugin cần thiết.
3. `backend`: Cấu hình vị trí lưu trữ file state (local hoặc remote như S3).
4. `cloud`: Sử dụng HCP Terraform.
5. `experiments`: Bật các tính năng thử nghiệm.
6. `provider_meta`: Cung cấp metadata cho provider (ít dùng).

## 6. Tính chất phi tuần tự của HCL
* Trong HCL, **thứ tự dòng hoặc thứ tự khai báo các block không quan trọng**.
* Terraform không thực thi code từ trên xuống dưới. Nó nạp toàn bộ cấu hình vào bộ nhớ, tự động phân tích các tham chiếu chéo giữa các tài nguyên để dựng thành một **Đồ thị phụ thuộc (Dependency Graph)** và tự quyết định thứ tự thực thi hợp lý nhất.
