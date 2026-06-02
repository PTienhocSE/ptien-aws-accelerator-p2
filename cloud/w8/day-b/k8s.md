# Canvas lý thuyết Kubernetes cho người mới

## 1. Container là gì?

Container là cách đóng gói ứng dụng cùng môi trường chạy của nó.

Một ứng dụng backend thường cần nhiều thứ để chạy:

```txt
Source code
Runtime: Node.js, Java, .NET, Python
Thư viện phụ thuộc
Biến môi trường
Command để start app
Port để nhận request
```

Trước đây, nếu deploy app lên server, phải cài mọi thứ trực tiếp lên máy chủ. Vấn đề là mỗi máy có thể khác nhau:

```txt
Máy dev dùng Node 20
Máy server dùng Node 18
Máy tester thiếu thư viện
Máy production khác OS
```

Container giải quyết bằng cách đóng gói app vào một môi trường nhất quán.

Hiểu đơn giản:

```txt
Container = một “hộp” chứa app và môi trường cần thiết để app chạy.
```

Ví dụ thực tế:

```txt
JobMate API cần .NET/Node.js, thư viện, config, port.
Đóng gói vào container thì chạy ở laptop, server, cloud đều giống nhau hơn.
```

Container giúp:

```txt
Dễ deploy
Dễ tái tạo môi trường
Ít lỗi kiểu “máy em chạy được”
Nhẹ hơn máy ảo
Phù hợp microservices
```

---

## 2. Image là gì?

Image là bản mẫu để tạo container.

Có thể hiểu:

```txt
Image = bản đóng gói tĩnh
Container = image đang chạy
```

Ví dụ:

```txt
jobmate-api-image
```

Từ image này có thể chạy ra nhiều container:

```txt
container 1
container 2
container 3
```

Tương tự như:

```txt
Class = image
Object = container
```

Hoặc:

```txt
Bản thiết kế nhà = image
Căn nhà thật được xây = container
```

---

## 3. Vì sao Docker chưa đủ?

Docker giúp chạy container, nhưng khi hệ thống lớn hơn sẽ phát sinh nhiều vấn đề.

Ví dụ backend có nhiều người dùng hơn, cần chạy 5 container API:

```txt
api-container-1
api-container-2
api-container-3
api-container-4
api-container-5
```

Lúc này có nhiều câu hỏi:

```txt
Ai đảm bảo đủ 5 container luôn chạy?
Container chết thì ai restart?
Traffic chia vào container nào?
Deploy version mới thế nào để không downtime?
Làm sao scale lên/xuống tự động?
Làm sao quản lý config và secret?
Làm sao giới hạn container nào được gọi database?
```

Docker đơn lẻ không giải quyết tốt toàn bộ các bài toán đó.

Đó là lý do cần Kubernetes.

---

## 4. Orchestration là gì?

Orchestration nghĩa là điều phối.

Trong bối cảnh container:

```txt
Container orchestration = điều phối nhiều container để hệ thống chạy ổn định.
```

Nó bao gồm:

```txt
Chạy container
Theo dõi container
Restart khi lỗi
Scale số lượng container
Chia traffic
Deploy phiên bản mới
Quản lý cấu hình
Quản lý secret
Quản lý network
Quản lý tài nguyên CPU/RAM
```

Nếu container là từng nhạc công, thì Kubernetes giống nhạc trưởng.

```txt
Container = người chơi nhạc
Kubernetes = nhạc trưởng điều phối cả dàn nhạc
```

---

## 5. Kubernetes là gì?

Kubernetes, viết tắt là K8s, là nền tảng điều phối container.

Nó giúp quản lý ứng dụng container ở quy mô lớn.

Hiểu đơn giản:

```txt
Kubernetes = hệ thống quản lý container tự động.
```

Nó không chỉ chạy app, mà còn đảm bảo app luôn ở trạng thái mong muốn.

Ví dụ ta muốn:

```txt
Backend API luôn có 3 bản chạy
Nếu 1 bản chết thì tự tạo bản mới
Nếu traffic tăng thì scale lên
Nếu deploy version mới thì thay dần version cũ
Nếu app chưa sẵn sàng thì không nhận traffic
```

Kubernetes làm những việc đó.

---

# 6. Tư duy quan trọng nhất: Desired State

Đây là tư duy cốt lõi của Kubernetes.

Khi dùng Kubernetes, ta không điều khiển từng bước thủ công.

Ta không nói:

```txt
Chạy container A
Restart container B
Tạo thêm container C
Xóa container D
```

Mà ta khai báo:

```txt
Tôi muốn hệ thống có trạng thái như thế này.
```

Ví dụ:

```txt
Ứng dụng backend phải luôn có 3 bản chạy.
```

Kubernetes sẽ tự so sánh:

```txt
Desired state: 3 bản
Current state: 2 bản
=> Kubernetes tạo thêm 1 bản
```

Hoặc:

```txt
Desired state: image version 2
Current state: image version 1
=> Kubernetes rollout version mới
```

Đây là tư duy rất giống Terraform:

```txt
Terraform: desired state cho hạ tầng.
Kubernetes: desired state cho ứng dụng/container.
```

---

# 7. Cluster là gì?

Cluster là toàn bộ môi trường Kubernetes.

Một cluster gồm:

```txt
Control Plane
Worker Nodes
Network
Storage
Kubernetes resources
```

Hiểu đơn giản:

```txt
Cluster = một cụm máy chạy Kubernetes.
```

Ví dụ:

```txt
Một Kubernetes cluster có thể có 3 máy worker.
Các app của mình sẽ được phân bổ chạy trên các máy đó.
```

---

# 8. Node là gì?

Node là một máy trong Kubernetes cluster.

Node có thể là:

```txt
Máy vật lý
Máy ảo
EC2 instance trên AWS
```

Có 2 loại chính:

```txt
Control Plane Node
Worker Node
```

## Control Plane Node

Là nơi điều khiển cluster.

Nó quyết định:

```txt
App nào chạy ở đâu
Khi nào cần tạo Pod mới
Khi nào cần restart
Khi nào cần scale
Trạng thái cluster hiện tại là gì
```

## Worker Node

Là nơi thật sự chạy ứng dụng.

Ví dụ:

```txt
jobmate-api
frontend
redis
worker service
```

sẽ chạy trên worker node.

---

# 9. Control Plane là gì?

Control Plane là bộ não của Kubernetes.

Nó không chạy ứng dụng chính của mình, mà quản lý cluster.

Các nhiệm vụ chính:

```txt
Nhận yêu cầu từ người dùng hoặc CI/CD
Lưu trạng thái mong muốn
Lên lịch Pod chạy trên node nào
Theo dõi trạng thái thực tế
Điều chỉnh hệ thống nếu có sai lệch
```

Các thành phần lý thuyết cần biết:

## API Server

Là cổng giao tiếp trung tâm của Kubernetes.

Tất cả lệnh quản lý cluster đều đi qua API Server.

Ví dụ khi dùng kubectl, thực chất là đang gửi request đến API Server.

```txt
kubectl -> API Server -> Kubernetes xử lý
```

## etcd

Là database lưu trạng thái cluster.

Nó lưu thông tin như:

```txt
Có những Pod nào
Có Deployment nào
Config hiện tại là gì
Secret nào đang tồn tại
Desired state là gì
```

Có thể hiểu:

```txt
etcd = bộ nhớ trạng thái của Kubernetes.
```

## Scheduler

Scheduler quyết định Pod sẽ chạy trên node nào.

Nó xem xét:

```txt
Node nào còn CPU/RAM
Pod cần tài nguyên bao nhiêu
Có rule placement nào không
Node có phù hợp không
```

## Controller Manager

Controller Manager liên tục kiểm tra:

```txt
Trạng thái hiện tại có đúng với trạng thái mong muốn không?
```

Nếu không đúng, nó điều chỉnh.

Ví dụ:

```txt
Muốn 3 Pod nhưng chỉ còn 2 Pod
=> Controller tạo thêm Pod
```

---

# 10. Worker Node gồm những gì?

Worker node là nơi chạy ứng dụng.

Các thành phần chính:

## Kubelet

Kubelet là agent chạy trên mỗi node.

Nhiệm vụ:

```txt
Nhận chỉ đạo từ Control Plane
Tạo Pod
Theo dõi Pod
Báo trạng thái Pod về Control Plane
```

Hiểu đơn giản:

```txt
Kubelet = người quản lý tại từng node.
```

## Container Runtime

Là phần thật sự chạy container.

Ví dụ:

```txt
containerd
CRI-O
Docker Engine trước đây
```

Kubernetes không tự chạy container trực tiếp. Nó nhờ container runtime chạy.

## Kube-proxy

Kube-proxy xử lý network routing cho Service.

Nó giúp traffic đi đúng đến Pod phía sau Service.

---

# 11. Pod là gì?

Pod là đơn vị nhỏ nhất Kubernetes dùng để chạy ứng dụng.

Điểm quan trọng:

```txt
Kubernetes không chạy container trực tiếp.
Kubernetes chạy Pod.
Container nằm bên trong Pod.
```

Một Pod thường chứa một container chính.

Ví dụ:

```txt
Pod jobmate-api
└── container jobmate-api
```

Có thể có nhiều container trong một Pod, nhưng người mới nên hiểu trước:

```txt
1 Pod thường tương ứng với 1 instance của app.
```

Ví dụ backend chạy 3 bản:

```txt
jobmate-api-pod-1
jobmate-api-pod-2
jobmate-api-pod-3
```

Mỗi Pod có:

```txt
IP riêng
Container riêng
Log riêng
Vòng đời riêng
```

Nhưng Pod không bền vững. Pod có thể chết, bị xóa, được tạo lại, đổi IP.

Vì vậy trong production không nên phụ thuộc trực tiếp vào Pod IP.

---

# 12. Vì sao không nên tạo Pod trực tiếp?

Pod có vòng đời ngắn.

Nếu tạo Pod trực tiếp, khi Pod chết, không có cơ chế mạnh để đảm bảo nó được thay thế đúng cách.

Trong thực tế người ta dùng Deployment để quản lý Pod.

So sánh:

```txt
Pod trực tiếp = chạy thủ công một instance
Deployment = quản lý nhiều Pod theo desired state
```

Production cần:

```txt
Tự tạo lại Pod khi chết
Scale nhiều replicas
Rolling update
Rollback
Quản lý version
```

Deployment làm việc đó tốt hơn Pod trực tiếp.

---

# 13. Deployment là gì?

Deployment là resource dùng để quản lý ứng dụng stateless.

Nó đảm bảo số lượng Pod luôn đúng như mong muốn.

Ví dụ:

```txt
Deployment jobmate-api muốn có 3 replicas.
```

Kubernetes sẽ giữ:

```txt
3 Pod API luôn tồn tại.
```

Nếu 1 Pod chết:

```txt
Còn 2 Pod
Deployment tạo thêm 1 Pod mới
```

Nếu update version:

```txt
Deployment thay Pod cũ bằng Pod mới từng bước
```

Deployment giúp:

```txt
Scale app
Rolling update
Rollback
Self-healing
Quản lý replicas
```

---

# 14. Replica là gì?

Replica là một bản chạy của ứng dụng.

Ví dụ:

```txt
replicas = 3
```

Nghĩa là Kubernetes sẽ chạy 3 Pod giống nhau.

Với backend API:

```txt
Pod 1 nhận request
Pod 2 nhận request
Pod 3 nhận request
```

Lợi ích:

```txt
Chịu tải tốt hơn
Nếu 1 Pod chết vẫn còn Pod khác
Có thể update không downtime
```

---

# 15. ReplicaSet là gì?

ReplicaSet là resource đảm bảo số lượng Pod luôn đúng.

Tuy nhiên thực tế thường không làm việc trực tiếp với ReplicaSet.

Luồng thường là:

```txt
Deployment quản lý ReplicaSet
ReplicaSet quản lý Pod
```

Hiểu đơn giản:

```txt
Deployment = cấp cao hơn
ReplicaSet = đảm bảo số lượng Pod
Pod = nơi chạy container
```

---

# 16. Label là gì?

Label là nhãn gắn vào resource Kubernetes.

Ví dụ:

```txt
app = jobmate-api
env = production
tier = backend
```

Label giúp phân loại và tìm resource.

Ví dụ có nhiều Pod:

```txt
Pod A: app=jobmate-api
Pod B: app=jobmate-api
Pod C: app=redis
Pod D: app=frontend
```

Kubernetes dùng label để biết Pod nào thuộc app nào.

---

# 17. Selector là gì?

Selector là cách chọn resource dựa trên label.

Ví dụ Service muốn tìm các Pod backend thì dùng selector:

```txt
app = jobmate-api
```

Nó sẽ chọn tất cả Pod có label đó.

Hiểu đơn giản:

```txt
Label = nhãn được gắn
Selector = bộ lọc để tìm nhãn
```

Nếu label và selector sai lệch, Service hoặc Deployment sẽ không tìm được Pod.

Đây là lỗi rất phổ biến với người mới.

---

# 18. Service là gì?

Pod có IP riêng, nhưng IP của Pod không ổn định.

Khi Pod chết và được tạo lại:

```txt
Pod cũ: IP A
Pod mới: IP B
```

Nếu app khác gọi trực tiếp IP của Pod, hệ thống sẽ lỗi.

Service giải quyết bằng cách cung cấp một địa chỉ ổn định để truy cập nhóm Pod.

Hiểu đơn giản:

```txt
Service = địa chỉ cố định đứng trước nhiều Pod.
```

Luồng:

```txt
Client -> Service -> Pod 1 / Pod 2 / Pod 3
```

Service làm 2 việc chính:

```txt
Cung cấp endpoint ổn định
Load balance traffic đến các Pod phù hợp
```

Ví dụ:

```txt
Frontend không gọi trực tiếp Pod backend.
Frontend gọi backend Service.
Service tự chuyển request đến một Pod backend còn sống.
```

---

# 19. Vì sao Service quan trọng?

Vì Pod là tạm thời.

Trong Kubernetes, Pod có thể:

```txt
Bị xóa
Bị restart
Bị tạo lại
Chuyển sang node khác
Đổi IP
```

Service giúp che giấu sự thay đổi đó.

App khác chỉ cần biết:

```txt
Tên Service
Port Service
```

Không cần biết Pod nào đang sống.

---

# 20. Các loại Service

## ClusterIP

Đây là loại mặc định.

Dùng để expose app bên trong cluster.

Ví dụ:

```txt
Frontend gọi Backend
Backend gọi Redis
Backend gọi internal service
```

ClusterIP không expose trực tiếp ra Internet.

Dùng khi:

```txt
Service chỉ cần dùng nội bộ.
```

## NodePort

Expose service qua port trên mỗi node.

Ví dụ:

```txt
NodeIP:Port -> Service -> Pod
```

Loại này thường dùng học tập/lab hơn là production.

## LoadBalancer

Dùng trên môi trường cloud.

Khi tạo Service loại LoadBalancer, cloud provider sẽ tạo load balancer bên ngoài.

Ví dụ trên AWS:

```txt
Kubernetes Service LoadBalancer
=> AWS tạo Load Balancer
=> User ngoài Internet truy cập được app
```

Dùng khi:

```txt
Muốn expose app ra bên ngoài cluster.
```

---

# 21. Ingress là gì?

Ingress là resource quản lý truy cập HTTP/HTTPS vào cluster.

Service giúp expose app, nhưng nếu có nhiều app/domain/path thì dùng Ingress dễ quản lý hơn.

Ví dụ:

```txt
jobmate.com           -> frontend
api.jobmate.com       -> backend
jobmate.com/api       -> backend
jobmate.com/admin     -> admin dashboard
```

Ingress thường cần Ingress Controller.

Ví dụ:

```txt
NGINX Ingress Controller
AWS Load Balancer Controller
Traefik
```

Nên hiểu:

```txt
Service = networking nội bộ hoặc expose cơ bản
Ingress = routing HTTP/HTTPS thông minh theo domain/path
```

---

# 22. Probe là gì?

Probe là cơ chế Kubernetes dùng để kiểm tra trạng thái container/app.

Một container “đang chạy” chưa chắc app bên trong “hoạt động tốt”.

Ví dụ:

```txt
Process vẫn còn sống
Nhưng app bị treo
Database chưa connect được
App chưa load config xong
API chưa sẵn sàng nhận request
```

Kubernetes dùng probe để biết nên:

```txt
Restart container?
Ngừng gửi traffic vào Pod?
Chờ app khởi động thêm?
```

Có 3 loại quan trọng:

```txt
Liveness Probe
Readiness Probe
Startup Probe
```

---

# 23. Liveness Probe là gì?

Liveness Probe kiểm tra app còn sống không.

Nếu liveness probe fail, Kubernetes sẽ restart container.

Dùng cho trường hợp:

```txt
App bị treo
App deadlock
Process còn nhưng không xử lý được request
App rơi vào trạng thái lỗi không tự phục hồi
```

Tư duy:

```txt
Nếu app không còn sống đúng nghĩa, restart nó.
```

Ví dụ:

```txt
Backend vẫn chạy process, nhưng mọi request đều timeout.
Liveness probe fail.
Kubernetes restart container.
```

---

# 24. Readiness Probe là gì?

Readiness Probe kiểm tra app đã sẵn sàng nhận traffic chưa.

Nếu readiness probe fail:

```txt
Kubernetes không gửi traffic vào Pod đó.
Nhưng không nhất thiết restart container.
```

Dùng cho trường hợp:

```txt
App đang khởi động
App chưa connect database xong
App đang warm up cache
App tạm thời không sẵn sàng
```

Tư duy:

```txt
App chưa ready thì đừng cho nhận request.
```

Ví dụ:

```txt
JobMate API vừa start.
Nó cần connect PostgreSQL, Redis, load config.
Trong thời gian đó, readiness fail.
Service chưa route traffic vào Pod.
Khi API sẵn sàng, readiness pass.
Service bắt đầu route traffic.
```

---

# 25. Startup Probe là gì?

Startup Probe dùng cho app khởi động chậm.

Nếu không có startup probe, liveness probe có thể check quá sớm và tưởng app bị lỗi.

Kết quả:

```txt
App chưa kịp start
Liveness probe fail
Kubernetes restart
App lại chưa kịp start
Restart loop
```

Startup probe nói với Kubernetes:

```txt
Hãy chờ app khởi động xong trước khi dùng liveness probe.
```

Dùng cho:

```txt
Java app
.NET app lớn
App cần migration/cache warmup
App AI service load model lâu
```

---

# 26. So sánh 3 loại Probe

| Loại probe      | Mục đích                                | Khi fail thì sao?                 | Dùng khi nào                           |
| --------------- | --------------------------------------- | --------------------------------- | -------------------------------------- |
| Startup Probe   | Kiểm tra app đã khởi động xong chưa     | Chờ thêm hoặc restart nếu quá lâu | App start chậm                         |
| Readiness Probe | Kiểm tra app sẵn sàng nhận traffic chưa | Không gửi traffic vào Pod         | App cần DB/cache/config sẵn sàng       |
| Liveness Probe  | Kiểm tra app còn sống không             | Restart container                 | App bị treo hoặc lỗi không tự phục hồi |

Cách nhớ:

```txt
Startup = đã khởi động xong chưa?
Readiness = đã sẵn sàng nhận request chưa?
Liveness = còn sống không?
```

---

# 27. ConfigMap là gì?

ConfigMap dùng để lưu cấu hình không nhạy cảm.

Ví dụ:

```txt
APP_ENV = production
LOG_LEVEL = info
API_TIMEOUT = 5000
FEATURE_AI_INTERVIEW = true
```

Lý do cần ConfigMap:

```txt
Không nên hard-code config vào source code.
Một image có thể chạy ở nhiều môi trường khác nhau.
Dev/staging/prod có config khác nhau.
```

Ví dụ:

```txt
Cùng một image jobmate-api
Ở dev: LOG_LEVEL=debug
Ở production: LOG_LEVEL=info
```

Nếu hard-code, mỗi lần đổi config phải build image mới.

Nếu dùng ConfigMap, chỉ cần đổi config bên ngoài.

---

# 28. Secret là gì?

Secret dùng để lưu thông tin nhạy cảm.

Ví dụ:

```txt
Database password
JWT secret
API key
OAuth client secret
Payment secret
AWS credential
```

Secret giúp tách dữ liệu nhạy cảm khỏi source code và image.

Tuy nhiên cần nhớ:

```txt
Kubernetes Secret mặc định không phải tuyệt đối an toàn.
Nó thường được encode base64.
Production cần kết hợp encryption, RBAC, external secret manager.
```

Trên AWS, thường kết hợp:

```txt
AWS Secrets Manager
AWS KMS
External Secrets Operator
IAM Roles for Service Accounts
```

---

# 29. ConfigMap vs Secret

| Tiêu chí           | ConfigMap                      | Secret                  |
| ------------------ | ------------------------------ | ----------------------- |
| Dùng cho           | Config thường                  | Dữ liệu nhạy cảm        |
| Ví dụ              | APP_ENV, LOG_LEVEL             | DB_PASSWORD, JWT_SECRET |
| Có nên public?     | Có thể trong một số trường hợp | Không                   |
| Có nên commit Git? | Có thể nếu không nhạy cảm      | Không nên               |
| Rủi ro nếu lộ      | Thấp hơn                       | Cao                     |

Cách nhớ:

```txt
Cái gì lộ ra không nguy hiểm nhiều -> ConfigMap.
Cái gì lộ ra có thể mất tiền/mất dữ liệu/mất quyền truy cập -> Secret.
```

---

# 30. NetworkPolicy là gì?

NetworkPolicy là cơ chế kiểm soát traffic giữa các Pod.

Mặc định trong nhiều cluster, các Pod có thể giao tiếp khá tự do với nhau.

Điều này nguy hiểm.

Ví dụ hệ thống có:

```txt
Frontend
Backend API
PostgreSQL
Redis
Admin service
```

Không nên để:

```txt
Frontend gọi trực tiếp PostgreSQL
Pod lạ gọi Redis
Service không liên quan gọi backend nội bộ
```

NetworkPolicy giúp định nghĩa:

```txt
Ai được gọi ai
Được gọi qua port nào
Traffic vào được phép hay không
Traffic ra được phép hay không
```

Hiểu đơn giản:

```txt
NetworkPolicy = firewall nội bộ giữa các Pod.
```

---

# 31. Ingress và Egress trong NetworkPolicy

NetworkPolicy có 2 hướng traffic:

## Ingress

Traffic đi vào Pod.

Ví dụ:

```txt
Ai được gọi backend?
Ai được gọi database?
Ai được gọi Redis?
```

## Egress

Traffic đi ra từ Pod.

Ví dụ:

```txt
Backend được gọi database không?
Backend được gọi Internet không?
Backend được gọi Redis không?
```

Ví dụ tư duy bảo mật:

```txt
Frontend:
- Được gọi backend
- Không được gọi database

Backend:
- Được nhận request từ frontend/ingress
- Được gọi database, Redis, external AI API

Database:
- Chỉ nhận request từ backend

Redis:
- Chỉ nhận request từ backend
```

---

# 32. Default allow và default deny

Một điểm rất quan trọng:

```txt
Nếu không có NetworkPolicy, thường traffic được allow khá rộng.
```

Khi áp dụng NetworkPolicy cho một nhóm Pod, có thể chuyển sang mô hình hạn chế hơn.

Best practice bảo mật:

```txt
Default deny trước
Sau đó allow những traffic cần thiết
```

Tư duy giống security group:

```txt
Chặn hết trước
Mở đúng cái cần
```

---

# 33. NetworkPolicy có luôn hoạt động không?

Không phải lúc nào cũng hoạt động.

NetworkPolicy cần network plugin hỗ trợ.

Một số plugin phổ biến:

```txt
Calico
Cilium
Weave Net
```

Nếu cluster không có plugin hỗ trợ, có thể tạo NetworkPolicy nhưng không enforce được.

Vì vậy khi học K8s cần nhớ:

```txt
NetworkPolicy là Kubernetes resource.
Nhưng việc thực thi phụ thuộc vào CNI plugin.
```

---

# 34. Namespace là gì?

Namespace dùng để chia cluster thành nhiều không gian logic.

Ví dụ:

```txt
dev
staging
production
monitoring
security
```

Lợi ích:

```txt
Tách môi trường
Dễ quản lý resource
Dễ phân quyền
Dễ giới hạn quota
Dễ tổ chức hệ thống lớn
```

Ví dụ:

```txt
jobmate-dev
jobmate-staging
jobmate-prod
```

Cùng một app có thể tồn tại ở nhiều namespace khác nhau:

```txt
jobmate-api trong dev
jobmate-api trong staging
jobmate-api trong production
```

---

# 35. Resource Request và Limit là gì?

Kubernetes cần biết mỗi Pod cần bao nhiêu tài nguyên.

## Request

Request là lượng tài nguyên tối thiểu Pod cần để được schedule.

Ví dụ:

```txt
Pod cần ít nhất 256MB RAM và 0.25 CPU.
```

Scheduler dùng request để quyết định Pod chạy trên node nào.

## Limit

Limit là mức tối đa Pod được dùng.

Ví dụ:

```txt
Pod không được dùng quá 512MB RAM và 1 CPU.
```

Nếu không đặt request/limit, có thể xảy ra:

```txt
Một Pod ăn hết CPU/RAM
Pod khác bị ảnh hưởng
Node bị quá tải
Hệ thống khó scale
```

Tư duy DevOps:

```txt
Request giúp scheduling đúng.
Limit giúp bảo vệ cluster.
```

---

# 36. Stateful và Stateless

Khi học K8s phải phân biệt stateless và stateful.

## Stateless app

App không lưu trạng thái quan trọng bên trong container.

Ví dụ:

```txt
Backend API
Frontend
Worker xử lý job
```

Nếu Pod chết, tạo Pod mới không mất dữ liệu quan trọng.

Stateless app phù hợp với Deployment.

## Stateful app

App có trạng thái/dữ liệu cần giữ.

Ví dụ:

```txt
Database
Redis persistent mode
Kafka
Elasticsearch
```

Stateful app cần quản lý danh tính, storage, thứ tự khởi động kỹ hơn.

Kubernetes có StatefulSet cho loại này.

Người mới nên nhớ:

```txt
API/frontend thường dùng Deployment.
Database/cache persistent thường cần StatefulSet hoặc dịch vụ managed bên ngoài.
```

Trên AWS production, thường ưu tiên:

```txt
App chạy trên EKS
Database dùng RDS
Redis dùng ElastiCache
Storage dùng S3/EFS
```

Không nhất thiết tự chạy database trong Kubernetes.

---

# 37. Volume là gì?

Container mặc định có filesystem tạm thời.

Nếu container chết, dữ liệu trong container có thể mất.

Volume giúp gắn storage bền hơn cho Pod.

Dùng cho:

```txt
File upload tạm
Cache
Log
Database data
Shared files
```

Nhưng với production cloud, cần suy nghĩ kỹ:

```txt
File user upload nên dùng S3
Database nên dùng RDS
Shared filesystem có thể dùng EFS
```

Không nên lưu dữ liệu quan trọng trực tiếp trong container.

---

# 38. Service Discovery là gì?

Service discovery là cách các service tìm thấy nhau.

Trong Kubernetes, mỗi Service có DNS name nội bộ.

Ví dụ:

```txt
Backend muốn gọi Redis
Không cần biết Redis Pod IP
Chỉ cần gọi Redis Service
```

Kubernetes DNS giúp phân giải tên Service sang IP tương ứng.

Ý nghĩa:

```txt
Service có thể thay Pod phía sau mà client không cần biết.
```

Đây là nền tảng của microservices trong Kubernetes.

---

# 39. Rolling Update là gì?

Rolling update là cách deploy version mới từng bước.

Ví dụ backend đang có 3 Pod version 1:

```txt
api-v1
api-v1
api-v1
```

Deploy version 2:

```txt
Tạo 1 Pod v2
Đợi Pod v2 ready
Xóa 1 Pod v1
Tạo thêm Pod v2
Đợi ready
Xóa tiếp Pod v1
```

Kết quả:

```txt
Không downtime nếu readiness probe đúng.
```

Rolling update giúp:

```txt
Deploy an toàn hơn
Không tắt toàn bộ app cùng lúc
Có thể rollback nếu lỗi
```

---

# 40. Rollback là gì?

Rollback là quay lại version trước khi version mới lỗi.

Ví dụ:

```txt
Deploy jobmate-api v2
Sau đó phát hiện lỗi payment
Rollback về v1
```

Kubernetes Deployment hỗ trợ rollback vì nó quản lý lịch sử ReplicaSet.

Tư duy production:

```txt
Không chỉ cần deploy được.
Phải rollback được.
```

---

# 41. Auto-healing là gì?

Auto-healing nghĩa là hệ thống tự phục hồi khi có lỗi.

Kubernetes có thể:

```txt
Restart container lỗi
Tạo lại Pod chết
Không route traffic vào Pod chưa ready
Reschedule Pod sang node khác nếu node lỗi
```

Ví dụ:

```txt
Một Pod backend bị crash.
Deployment phát hiện thiếu replica.
Kubernetes tạo Pod mới.
Service chỉ route vào Pod healthy.
```

Đây là một trong những giá trị lớn nhất của Kubernetes.

---

# 42. Scaling là gì?

Scaling là tăng hoặc giảm số lượng instance của app.

Có 2 kiểu:

## Manual scaling

Người vận hành tự chỉnh số replicas.

Ví dụ:

```txt
Từ 3 Pod lên 5 Pod.
```

## Auto scaling

Kubernetes tự scale dựa trên metric.

Ví dụ:

```txt
CPU cao -> tăng Pod
CPU thấp -> giảm Pod
```

Resource liên quan:

```txt
HPA: Horizontal Pod Autoscaler
VPA: Vertical Pod Autoscaler
Cluster Autoscaler
Karpenter
```

Người mới chỉ cần nắm:

```txt
Pod scaling = tăng/giảm số Pod.
Node scaling = tăng/giảm số máy trong cluster.
```

---

# 43. HPA là gì?

HPA là Horizontal Pod Autoscaler.

Nó tự động tăng/giảm số Pod dựa trên metric.

Ví dụ:

```txt
Nếu CPU > 70%, tăng replicas.
Nếu CPU thấp, giảm replicas.
```

Dùng cho:

```txt
Backend API
Worker
Frontend SSR
```

Lưu ý:

```txt
Muốn HPA hoạt động tốt, cần đặt resource requests đúng.
```

---

# 44. Cluster Autoscaler/Karpenter là gì?

HPA scale Pod, nhưng nếu node không đủ chỗ thì sao?

Khi đó cần scale node.

Cluster Autoscaler hoặc Karpenter giúp:

```txt
Thêm node khi cluster thiếu tài nguyên.
Giảm node khi dư tài nguyên.
```

Trên AWS EKS, Karpenter rất phổ biến.

Tư duy:

```txt
HPA scale workload.
Karpenter/Cluster Autoscaler scale infrastructure.
```

---

# 45. Scheduling là gì?

Scheduling là quá trình chọn node để chạy Pod.

Scheduler xem xét:

```txt
Node còn CPU/RAM không
Pod cần tài nguyên bao nhiêu
Pod có yêu cầu chạy ở node đặc biệt không
Có taint/toleration không
Có affinity/anti-affinity không
```

Ví dụ:

```txt
Pod cần 2GB RAM.
Node A chỉ còn 1GB.
Node B còn 4GB.
Scheduler chọn Node B.
```

---

# 46. Taint và Toleration là gì?

Taint dùng để “xua đuổi” Pod khỏi một node, trừ khi Pod có toleration phù hợp.

Dùng khi muốn node chỉ dành cho workload đặc biệt.

Ví dụ:

```txt
Node GPU chỉ cho AI workload.
Node database chỉ cho stateful workload.
Node system chỉ cho monitoring/security.
```

Tư duy:

```txt
Taint đặt trên node.
Toleration đặt trên Pod.
Pod chỉ chạy được trên node bị taint nếu chịu được taint đó.
```

---

# 47. Affinity và Anti-affinity là gì?

Affinity là quy tắc “thích chạy gần” hoặc “nên chạy ở đâu”.

Anti-affinity là quy tắc “không nên chạy gần nhau”.

Ví dụ affinity:

```txt
AI worker nên chạy trên node có GPU.
```

Ví dụ anti-affinity:

```txt
3 Pod backend không nên nằm cùng một node.
```

Vì nếu một node chết, cả 3 Pod backend chết cùng lúc.

Tư duy HA:

```txt
Spread Pod ra nhiều node/zone để tránh single point of failure.
```

---

# 48. RBAC là gì?

RBAC là Role-Based Access Control.

Nó kiểm soát ai được làm gì trong Kubernetes.

Ví dụ:

```txt
Dev chỉ được xem log trong namespace dev.
DevOps được deploy vào staging.
Admin được quản lý toàn cluster.
CI/CD chỉ được update deployment.
```

RBAC gồm các khái niệm:

```txt
Role
ClusterRole
RoleBinding
ClusterRoleBinding
ServiceAccount
```

Người mới cần hiểu:

```txt
RBAC = phân quyền trong Kubernetes.
```

---

# 49. ServiceAccount là gì?

ServiceAccount là danh tính cho workload bên trong Kubernetes.

Ví dụ:

```txt
Pod backend cần quyền đọc Secret.
CI/CD cần quyền update Deployment.
Controller cần quyền xem Pod/Service.
```

Không nên để mọi Pod dùng quyền mặc định quá rộng.

Trên AWS EKS, ServiceAccount có thể gắn với IAM role thông qua IRSA.

Ví dụ:

```txt
Pod cần truy cập S3
Không nên hard-code AWS key
Nên dùng IAM Role for Service Account
```

---

# 50. K8s và AWS liên hệ thế nào?

Trên AWS, Kubernetes managed service là EKS.

```txt
EKS = Elastic Kubernetes Service
```

AWS quản lý phần Control Plane cho mình.

Mình quản lý:

```txt
Worker nodes
Networking
IAM
Add-ons
Workloads
Monitoring
Security
Cost
```

Các dịch vụ thường liên quan:

```txt
EKS: Kubernetes cluster
EC2: worker node
Fargate: serverless pod runtime
ECR: lưu container image
ALB/NLB: expose app
IAM: phân quyền
CloudWatch: log/metrics
Secrets Manager: quản lý secret
RDS: database
ElastiCache: Redis
S3: object storage
EFS: shared filesystem
```

---

# 51. Tư duy kiến trúc khi dùng Kubernetes

Khi thiết kế app trên K8s, không chỉ hỏi “chạy thế nào”, mà phải hỏi:

## Availability

```txt
App có nhiều replicas chưa?
Pod có spread qua nhiều node/zone không?
Readiness/liveness có đúng không?
Rolling update có tránh downtime không?
```

## Scalability

```txt
Có thể scale Pod không?
Có HPA không?
Cluster có tự thêm node không?
Service có load balance không?
```

## Security

```txt
Secret có an toàn không?
RBAC có quá rộng không?
NetworkPolicy có chặn traffic không cần thiết không?
Image có vulnerability không?
Pod có chạy quyền root không?
```

## Observability

```txt
Có log không?
Có metric không?
Có alert không?
Có tracing không?
Có dashboard không?
```

## Cost

```txt
Pod request/limit có hợp lý không?
Node có bị dư tài nguyên không?
Autoscaling có scale down không?
Có workload nào chạy dư không?
```

---

# 52. Bức tranh tổng thể Kubernetes

Có thể hình dung như sau:

```txt
User
 |
Load Balancer / Ingress
 |
Service
 |
Deployment
 |
ReplicaSet
 |
Pods
 |
Containers
```

Bên cạnh đó:

```txt
ConfigMap cung cấp config thường
Secret cung cấp config nhạy cảm
Probe kiểm tra sức khỏe app
NetworkPolicy kiểm soát traffic
Namespace chia môi trường
RBAC phân quyền
HPA scale Pod
Volume cung cấp storage
```

---

# 53. Cách học đúng cho người mới

Không học Kubernetes bằng cách học YAML trước.

Nên học theo thứ tự:

```txt
1. Container là gì?
2. Vì sao cần orchestration?
3. Kubernetes giải quyết bài toán gì?
4. Cluster/Node/Control Plane/Worker Node là gì?
5. Pod là gì?
6. Vì sao cần Deployment?
7. Vì sao cần Service?
8. Probe giải quyết vấn đề gì?
9. ConfigMap/Secret dùng để tách config thế nào?
10. NetworkPolicy bảo vệ traffic ra sao?
11. Scaling, rolling update, rollback hoạt động thế nào?
12. Security/RBAC/ServiceAccount là gì?
13. Monitoring/logging trong K8s cần gì?
14. EKS liên hệ AWS như thế nào?
```

---

# 54. Checklist lý thuyết phải nắm

Sau khi học, cần tự trả lời được:

```txt
Container khác VM thế nào?
Image khác container thế nào?
Vì sao Docker chưa đủ cho production lớn?
Container orchestration là gì?
Kubernetes là gì?
Desired state là gì?
Cluster là gì?
Node là gì?
Control Plane làm gì?
Worker Node làm gì?
API Server là gì?
etcd là gì?
Scheduler là gì?
Kubelet là gì?
Pod là gì?
Vì sao Pod không bền vững?
Deployment là gì?
Replica là gì?
ReplicaSet là gì?
Service là gì?
Vì sao không gọi trực tiếp Pod IP?
ClusterIP, NodePort, LoadBalancer khác nhau thế nào?
Ingress là gì?
Label và Selector dùng để làm gì?
Probe là gì?
Liveness, Readiness, Startup khác nhau thế nào?
ConfigMap là gì?
Secret là gì?
NetworkPolicy là gì?
Ingress/Egress trong NetworkPolicy là gì?
Namespace là gì?
Request/Limit là gì?
Stateless và Stateful khác nhau thế nào?
Volume là gì?
Service discovery là gì?
Rolling update là gì?
Rollback là gì?
Auto-healing là gì?
HPA là gì?
Node autoscaling là gì?
Scheduling là gì?
Taint/Toleration là gì?
Affinity/Anti-affinity là gì?
RBAC là gì?
ServiceAccount là gì?
EKS liên hệ với AWS thế nào?
```

---

# 55. Bản tóm tắt cực ngắn

```txt
Container = đóng gói app.
Image = bản mẫu tạo container.
Kubernetes = hệ thống điều phối container.
Cluster = cụm Kubernetes.
Node = máy trong cluster.
Control Plane = bộ não.
Worker Node = nơi chạy app.
Pod = đơn vị nhỏ nhất để chạy container.
Deployment = quản lý Pod/replicas/update.
Service = endpoint ổn định cho Pod.
Probe = kiểm tra sức khỏe app.
ConfigMap = config không nhạy cảm.
Secret = dữ liệu nhạy cảm.
NetworkPolicy = firewall giữa các Pod.
Namespace = chia môi trường.
RBAC = phân quyền.
HPA = tự scale Pod.
Ingress = route HTTP/HTTPS vào cluster.
```

---

# 56. Cách liên hệ với JobMate

Nếu JobMate chạy trên Kubernetes:

```txt
Frontend Next.js chạy trong các frontend Pod.
Backend API chạy trong các backend Pod.
Deployment đảm bảo backend luôn có nhiều replicas.
Service giúp frontend gọi backend ổn định.
Ingress expose app ra domain.
Readiness probe đảm bảo backend chỉ nhận traffic khi DB/Redis sẵn sàng.
Liveness probe restart backend nếu app bị treo.
ConfigMap chứa APP_ENV, LOG_LEVEL.
Secret chứa DATABASE_URL, JWT_SECRET, GEMINI_API_KEY.
NetworkPolicy chỉ cho backend gọi database/Redis.
RBAC giới hạn quyền của CI/CD và developer.
HPA scale backend khi traffic tăng.
```

Tư duy cuối cùng cần nhớ:

```txt
Kubernetes không chỉ để “chạy container”.
Kubernetes dùng để vận hành ứng dụng production theo hướng tự phục hồi, dễ scale, dễ deploy, tách config, kiểm soát network và quản lý hệ thống theo desired state.
```
