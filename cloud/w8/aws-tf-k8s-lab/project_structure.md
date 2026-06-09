# PROJECT STRUCTURE AND PROVIDERS ARCHITECTURE

Tài liệu này mô tả chi tiết cấu trúc thư mục của dự án và cách các nhà cung cấp (Providers) trong Terraform được cấu hình, kết nối với nhau để hoàn thành bài thực hành tự động hóa Kubernetes trên AWS.

---

## 1. DIRECTORY STRUCTURE (CẤU TRÚC THƯ MỤC)

```text
aws-tf-k8s-lab/
├── .gitignore              # Chỉ định các tệp tin và thư mục Git sẽ bỏ qua (như *.tfstate, key .pem)
├── main.tf                 # Khai báo các providers và lấy dữ liệu Default VPC của AWS
├── variables.tf            # Khai báo các biến đầu vào của dự án (Region, Instance Type)
├── terraform.tfvars        # Gán giá trị cụ thể cho các biến đầu vào
├── security.tf             # Định nghĩa Security Groups (tường lửa) cho ALB và EC2
├── ssh_key.tf              # Tự động sinh cặp khóa SSH bảo mật
├── ec2.tf                  # Định nghĩa máy ảo EC2, dung lượng đĩa và User Data
├── alb.tf                  # Định nghĩa bộ cân bằng tải ALB, Target Group và Listener
├── outputs.tf              # Hiển thị kết quả đầu ra (ALB URL, EC2 IP, câu lệnh SSH)
├── evidence_pack.md        # Báo cáo minh chứng hoàn thành lab (kèm ảnh tương đối)
├── reading_guide.md        # Hướng dẫn lộ trình đọc hiểu code cho người mới bắt đầu
├── README.md               # Tài liệu hướng dẫn sử dụng và triển khai dự án chính thức
└── templates/
    ├── k8s-app.yaml        # File manifest của Kubernetes (Deployment 2 Pods + Service NodePort)
    └── setup.sh            # Script cài đặt Docker, Minikube, app K8s và socat
```

---

## 2. TERRAFORM PROVIDERS (CÁC NHÀ CUNG CẤP VÀ MỤC ĐÍCH)

Dự án sử dụng tổng cộng **4 Providers** để thực hiện tự động hóa. Việc chia nhỏ và sử dụng nhiều providers giúp đảm bảo tính mô-đun và giải quyết các bài toán chuyên biệt.

| Tên Provider | Nguồn (Source) | Vai trò và Mục đích trong Dự án |
| :--- | :--- | :--- |
| **`aws`** | `hashicorp/aws` | **Provider chính**: Quản lý và khởi tạo toàn bộ hạ tầng vật lý trên đám mây AWS bao gồm EC2 Instance, Application Load Balancer, Target Group, Listener, Security Groups, và Key Pair. |
| **`tls`** | `hashicorp/tls` | **Tạo khóa bảo mật**: Sinh khóa private/public key sử dụng thuật toán mã hóa RSA trực tiếp trong bộ nhớ của Terraform, không phụ thuộc vào AWS Console hay câu lệnh sinh khóa ngoài. |
| **`cloudinit`** | `hashicorp/cloudinit` | **Đóng gói cấu hình khởi động**: Đóng gói và biên dịch tệp script `setup.sh` (chứa mã cài đặt Minikube) thành định dạng chuẩn MIME đa phần (Multi-part MIME) để truyền vào thuộc tính `user_data` của EC2. |
| **`local`** | `hashicorp/local` | **Ghi tệp cục bộ**: Xuất nội dung khóa private key từ bộ nhớ của Terraform ghi trực tiếp xuống ổ cứng máy tính cá nhân của bạn dưới dạng tệp `minikube-key.pem`. |

---

## 3. PROVIDER WIRING MECHANISM (CƠ CHẾ KẾT NỐI GIỮA CÁC PROVIDER)

Để thỏa mãn yêu cầu sử dụng từ 2 providers trở lên và kết nối (wire) chúng lại, dự án thực hiện truyền dữ liệu đầu ra của provider này làm đầu vào của provider khác theo sơ đồ dưới đây:

### 3.1. Sơ đồ kết nối dữ liệu (Data Flow)

```
┌─────────────────────────────────┐
│     tls provider (ssh key)      │
└────────────────┬────────────────┘
                 │ (Truyền Public Key)
                 ▼
┌─────────────────────────────────┐
│       aws provider (EC2)        │◄────── (Truyền User Data đã biên dịch)
└────────────────┬────────────────┘
                 │ (Ghi Private Key)
                 ▼
┌─────────────────────────────────┐
│      local provider (File)      │
└─────────────────────────────────┘
```

### 3.2. Code minh chứng cơ chế kết nối

*   **Kết nối giữa `tls` và `aws`** (Nằm trong `ssh_key.tf`):
    Đầu ra `public_key_openssh` của resource `tls_private_key` thuộc provider `tls` được truyền trực tiếp vào đầu vào `public_key` của resource `aws_key_pair` thuộc provider `aws`.
    ```hcl
    resource "aws_key_pair" "deployer" {
      key_name   = "minikube-key-pair"
      public_key = tls_private_key.minikube_key.public_key_openssh
    }
    ```

*   **Kết nối giữa `cloudinit` và `aws`** (Nằm trong `ec2.tf`):
    Script khởi tạo được biên dịch từ data source `cloudinit_config` thuộc provider `cloudinit` được truyền trực tiếp vào thuộc tính `user_data` của máy ảo `aws_instance` thuộc provider `aws`.
    ```hcl
    resource "aws_instance" "minikube_node" {
      # ...
      user_data = data.cloudinit_config.minikube_setup.rendered
    }
    ```

*   **Kết nối giữa `tls` và `local`** (Nằm trong `ssh_key.tf`):
    Đầu ra `private_key_pem` của resource `tls_private_key` thuộc provider `tls` được truyền vào đầu vào `content` của resource `local_file` thuộc provider `local` để ghi tệp ra đĩa.
    ```hcl
    resource "local_file" "private_key" {
      content  = tls_private_key.minikube_key.private_key_pem
      filename = "${path.module}/minikube-key.pem"
    }
    ```

---

## 4. CHI TIẾT TỪNG TỆP TIN VÀ VAI TRÒ CỦA CHÚNG

1.  **`main.tf`**:
    Điểm khởi đầu của Terraform. Ngoài việc khai báo các providers, tệp này đóng vai trò truy vấn (query) để lấy thông tin của mạng mặc định (Default VPC) đang hoạt động trên tài khoản AWS của bạn mà không cần tạo mới.
2.  **`security.tf`**:
    Tường lửa bảo vệ hệ thống. Nó mở cổng `80` cho Load Balancer đón khách, mở cổng `22` cho bạn SSH, và mở cổng `30080` của EC2 nhưng chặn toàn bộ bên ngoài, chỉ cho phép traffic đi từ Load Balancer đi vào.
3.  **`ec2.tf` & `alb.tf`**:
    EC2 tạo máy chủ ảo để chạy Kubernetes. ALB tạo bộ cân bằng tải nhận tên miền DNS công khai và định tuyến lưu lượng vào cổng `30080` của máy chủ EC2.
4.  **`templates/setup.sh`**:
    Script tự động cài đặt Docker, tải Minikube và chạy nó dưới dạng Docker container. Cuối cùng, nó cấu hình chương trình `socat` chạy ngầm để chuyển đổi cổng từ EC2 vào mạng Minikube.
5.  **`templates/k8s-app.yaml`**:
    File manifest chứa mã cấu hình chạy ứng dụng Nginx hiển thị trang "Hello AWS" và Service NodePort cổng `30080`.

---

## 5. SYSTEM WORKFLOW AND TRAFFIC ROUTING (LUỒNG HOẠT ĐỘNG VÀ ĐỊNH TUYẾN)

Hệ thống hoạt động theo hai luồng chính: Luồng khởi tạo (Provisioning Workflow) và Luồng xử lý yêu cầu (Runtime Traffic Routing).

### 5.1. Luồng khởi tạo tự động (Provisioning Workflow)

Khi bạn gõ lệnh `terraform apply`, Terraform sẽ chạy các bước bất đồng bộ theo luồng sau:

```
[Bắt đầu] -> (1) Tạo khóa SSH qua 'tls'
                │
                ├──> (2a) Đăng ký Public Key lên AWS ('aws_key_pair')
                └──> (2b) Xuất Private Key ra tệp '.pem' cục bộ ('local_file')
                │
            (3) Khởi chạy EC2 & tạo ALB cùng lúc (AWS Parallel Provisioning)
                │
            (4) EC2 khởi động -> Cloud-init tự động kích hoạt
                │
                ├──> (4a) Cài đặt Docker, conntrack, socat, kubectl, Minikube
                ├──> (4b) Khởi chạy cụm Minikube (Docker driver)
                ├──> (4c) Triển khai tệp 'k8s-app.yaml' (2 Pods + NodePort Service)
                └──> (4d) Kích hoạt systemd service chạy 'socat' để forward cổng 30080
                │
            [Hoàn thành] -> ALB nhận diện EC2 đã Healthy và bắt đầu định tuyến
```

### 5.2. Luồng định tuyến xử lý yêu cầu (Runtime Traffic Routing)

Khi người dùng bên ngoài truy cập trang web thông qua địa chỉ của Load Balancer, gói tin dữ liệu sẽ đi qua các chặng sau:

1.  **Chặng 1 (Người dùng -> ALB)**:
    Trình duyệt web gửi yêu cầu HTTP (cổng `80`) đến tên miền DNS của ALB. Quy tắc bảo mật trong `alb_sg` chấp nhận yêu cầu này và chuyển hướng gói tin đến **Target Group** đăng ký ở cổng `30080`.
2.  **Chặng 2 (ALB -> EC2 Host)**:
    ALB chuyển tiếp gói tin vào địa chỉ IP của máy ảo EC2 tại cổng `30080`. Nhờ có quy tắc bảo mật trong `ec2_sg`, EC2 chấp nhận gói tin từ ALB.
3.  **Chặng 3 (EC2 Host -> Minikube)**:
    Trên hệ điều hành EC2, tiến trình **`socat`** (lắng nghe cổng `30080`) bắt lấy gói tin này và ngay lập tức chuyển tiếp (forward) nó vào địa chỉ IP ảo của cụm Minikube (`192.168.49.2:30080`).
4.  **Chặng 4 (Minikube -> Pod App)**:
    Bên trong K8s, **Service NodePort** (cổng `30080`) nhận dữ liệu, thực hiện cân bằng tải nội bộ và đẩy gói tin vào cổng `80` của một trong hai **Nginx Pods** đang chạy ứng dụng.
5.  **Chặng 5 (Phản hồi ngược lại)**:
    Pod Nginx trả về nội dung trang HTML "Hello AWS!", gói tin đi ngược lại toàn bộ hành trình trên để hiển thị trên trình duyệt của người dùng.
