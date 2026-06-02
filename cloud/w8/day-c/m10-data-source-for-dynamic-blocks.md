# Data Source, Hàm, Biểu Thức for và Dynamic Block

## 1. Data Source (Truy vấn dữ liệu từ xa)
* **Khái niệm:** Data Source cho phép bạn đọc các thông tin đang tồn tại thực tế trên Cloud Provider (như AWS) để đưa vào cấu hình mà không cần tạo mới hay quản lý chúng.
* **Mục đích:** Hạn chế việc hardcode các giá trị dễ thay đổi theo thời gian (ví dụ: ID của AMI, danh sách AZ khả dụng, ID của VPC mặc định).
* **Khai báo mẫu:**
  ```hcl
  # Lấy thông tin tài khoản AWS hiện tại đang chạy
  data "aws_caller_identity" "current" {}

  # Lấy danh sách Availability Zones khả dụng trong region
  data "aws_availability_zones" "available" {
    state = "available"
  }

  # Tìm kiếm AMI Amazon Linux 2023 mới nhất
  data "aws_ami" "al2023" {
    most_recent = true
    owners      = ["amazon"]
    filter {
      name   = "name"
      values = ["al2023-ami-2023.*-x86_64"]
    }
  }
  ```
* **Tham chiếu:** Được gọi thông qua cú pháp: `data.<resource_type>.<local_name>.<attribute>` (Ví dụ: `data.aws_ami.al2023.id`).

## 2. Biểu thức `for` (Biến đổi và lọc dữ liệu)
Biểu thức `for` trong HCL được sử dụng để duyệt qua một Collection (List, Set, Map) và biến đổi dữ liệu sang dạng khác. Có 2 dạng đầu ra chính:

### Dạng List (Dùng ngoặc vuông `[...]`):
* Duyệt qua collection và trả về một List mới. Có thể kết thúc bằng mệnh đề `if` để lọc bỏ phần tử.
* Ví dụ:
  ```hcl
  # Lọc bỏ cổng 22 khỏi danh sách
  web_ports = [for p in var.allowed_ports : p if p != 22]
  ```

### Dạng Map (Dùng ngoặc nhọn `{...}`):
* Duyệt qua collection và chuyển đổi các phần tử thành các cặp Khóa $\rightarrow$ Giá trị (`key => value`).
* Ví dụ:
  ```hcl
  port_desc = { for p in var.allowed_ports : p => "Cho phép truy cập cổng ${p}" }
  ```

## 3. Dynamic Block (Sinh cấu hình khối lồng lặp lại)
* **Khái niệm:** Dùng để sinh ra nhiều block cấu hình con lồng ghép bên trong một resource (ví dụ: các block `ingress` trong Security Group, các block `origin` trong CloudFront) dựa trên dữ liệu đầu vào.
* **Cấu trúc hoạt động:** Tương tự biểu thức `for` nhưng kết quả là tạo ra cấu trúc block thay vì trả về giá trị thô.
* **Khai báo mẫu:**
  ```hcl
  resource "aws_security_group" "web" {
    name_prefix = "web-sg-"

    dynamic "ingress" {
      for_each = local.web_ports # Lặp qua danh sách cổng
      content {
        description = "HTTP/HTTPS Port ${ingress.value}"
        from_port   = ingress.value # Nhận giá trị hiện tại
        to_port     = ingress.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
  ```
  * `for_each`: Chỉ định danh sách/tập hợp các phần tử để lặp.
  * `content`: Định nghĩa nội dung của block con được sinh ra.
  * `ingress.value`: Giá trị của phần tử hiện tại trong vòng lặp (lấy theo tên của block `dynamic "ingress"`).

* **Lưu ý thực tế:** Không lạm dụng dynamic block. Chỉ sử dụng khi số lượng block con thực sự thay đổi biến thiên tùy theo biến đầu vào. Nếu số lượng block là cố định, hãy khai báo tĩnh để giữ code sạch và dễ đọc hơn.
