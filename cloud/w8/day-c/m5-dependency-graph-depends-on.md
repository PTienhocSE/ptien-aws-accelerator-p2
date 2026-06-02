# Đồ Thị Phụ Thuộc: Implicit, depends_on, và -target

## 1. Cơ chế Đồ thị Phụ thuộc (Dependency Graph)
* Bản chất hoạt động của Terraform dựa trên một cấu trúc đồ thị có hướng (Directed Acyclic Graph - DAG).
* Trong đó, mỗi resource được coi là một **Đỉnh** (Node) và mỗi mối quan hệ phụ thuộc giữa các tài nguyên được coi là một **Cạnh** (Edge).
* Terraform phân tích toàn bộ cấu hình, sắp xếp topo (Topological Sort) để quyết định thứ tự hành động một cách tối ưu nhất.
* **Chạy song song (Parallelism):** Các tài nguyên nằm trên các nhánh độc lập (không có cạnh kết nối phụ thuộc lẫn nhau) sẽ được Terraform tạo song song cùng một lúc (mặc định tối đa 10 thao tác song song).

## 2. Phụ thuộc ngầm (Implicit Dependency)
* **Khái niệm:** Là loại phụ thuộc phổ biến nhất, xảy ra khi tài nguyên này tham chiếu đến thuộc tính của tài nguyên khác.
* **Ví dụ:**
  ```hcl
  resource "aws_s3_bucket" "data" {
    bucket_prefix = "tf-series-bai5-"
  }

  resource "aws_s3_bucket_versioning" "data" {
    bucket = aws_s3_bucket.data.id # Tham chiếu ngầm tạo ra sự phụ thuộc
  }
  ```
* Trong ví dụ này, `aws_s3_bucket_versioning.data` sử dụng ID của `aws_s3_bucket.data`. Terraform tự hiểu và đảm bảo S3 Bucket phải được tạo xong trước khi cấu hình Versioning.

## 3. Vì sao Destroy đảo ngược thứ tự đồ thị?
* **Nguyên lý:** Nếu B phụ thuộc vào A, quy trình tạo sẽ là `A -> B`. Quy trình xóa bắt buộc phải đảo ngược: gỡ bỏ `B` trước rồi mới xóa `A` (để tránh lỗi xung đột hệ thống vì tài nguyên A đang bị dựa vào bởi B).
* **Metadata trong State:** Khi bạn xóa một block resource ra khỏi file cấu hình `.tf`, Terraform không thể suy ra thứ tự xóa từ code. Lúc này, nó đọc metadata về mối quan hệ phụ thuộc được lưu trước đó trong file `state` để tiến hành gỡ bỏ ngược chiều một cách an toàn.

```text
   QUY TRÌNH TẠO (Thuận theo cạnh)        QUY TRÌNH XÓA (Ngược chiều cạnh)
   
     1. aws_s3_bucket.data                  1. aws_s3_bucket_versioning.data
              │                                      │
              ▼ (xong trước)                         ▼ (xóa trước)
     2. aws_s3_bucket_versioning.data        2. aws_s3_bucket.data
```

## 4. Phụ thuộc ẩn & Khai báo thủ công (`depends_on`)
* **Khái niệm:** Có những phụ thuộc chỉ xuất hiện ở tầng logic ứng dụng mà Terraform không thể tự suy ra được từ mã nguồn HCL do không có tham chiếu trực tiếp.
* **Giải pháp:** Sử dụng thuộc tính meta-argument `depends_on`.
* **Ví dụ:** Một máy chủ EC2 cần một IAM Policy đã sẵn sàng lúc khởi động để ứng dụng chạy ngầm, nhưng EC2 không tham chiếu trực tiếp thuộc tính nào từ Policy đó:
  ```hcl
  resource "aws_instance" "app" {
    # ...
    depends_on = [aws_iam_role_policy.app]
  }
  ```
* **Lưu ý thực hành:** Chỉ sử dụng `depends_on` như giải pháp cuối cùng. Sử dụng quá nhiều `depends_on` sẽ khiến Terraform lập kế hoạch dự phòng (dè dặt) hơn, dễ gây ra việc phá hủy và tạo lại nhiều tài nguyên không cần thiết. Hãy ưu tiên tham chiếu trực tiếp thuộc tính khi có thể.

## 5. Lệnh kiểm tra đồ thị `terraform graph`
* Lệnh `terraform graph` xuất ra định dạng đồ thị dạng DOT.
* Bạn có thể sử dụng công cụ Graphviz để chuyển đổi output của lệnh này thành dạng ảnh trực quan:
  ```bash
  terraform graph | dot -Tpng > graph.png
  ```

## 6. Cờ chỉ định mục tiêu `-target`
* **Khái niệm:** Cho phép chỉ thực thi kế hoạch/thay đổi trên một hoặc một nhóm tài nguyên cụ thể mà bạn nhắm tới.
* **Ví dụ:** `terraform apply -target=aws_s3_bucket.data`
* **Cảnh báo:** 
  * Cờ này chỉ dùng trong tình huống khẩn cấp hoặc debug (ví dụ xử lý một tài nguyên lỗi).
  * Việc lạm dụng `-target` làm lệch pha giữa thiết kế cấu hình và trạng thái state.
  * Nếu bạn thường xuyên phải dùng `-target` để tối ưu thời gian chạy, điều đó báo hiệu dự án cần được chia tách thành các State nhỏ hơn (Multi-State).
