# Application Deployment Contract
# 应用部署契约 - nginx+golang+前端完整栈

## 架构概览

```mermaid
graph TB
    subgraph "Internet"
        User[用户浏览器]
    end

    subgraph "Kubernetes Cluster"
        subgraph "Ingress Layer"
            Ingress[Nginx Ingress<br/>路由控制]
        end

        subgraph "Frontend Layer"
            FrontSvc[Frontend Service<br/>:3000]
            FrontPod1[Frontend Pod 1<br/>React/Vue]
            FrontPod2[Frontend Pod 2<br/>React/Vue]
            FrontSvc --> FrontPod1
            FrontSvc --> FrontPod2
        end

        subgraph "Backend Layer"
            BackSvc[Backend Service<br/>:8080]
            BackPod1[Backend Pod 1<br/>Golang API]
            BackPod2[Backend Pod 2<br/>Golang API]
            BackPod3[Backend Pod 3<br/>Golang API]
            BackSvc --> BackPod1
            BackSvc --> BackPod2
            BackSvc --> BackPod3
        end

        subgraph "Data Layer"
            Redis[Redis<br/>Session Store]
            Postgres[PostgreSQL<br/>Database]
        end

        subgraph "Config & Secrets"
            ConfigMap[ConfigMap<br/>应用配置]
            Secret[Secret<br/>凭据管理]
        end
    end

    User --> Ingress
    Ingress -->|/| FrontSvc
    Ingress -->|/api| BackSvc
    FrontPod1 -.->|API调用| BackSvc
    FrontPod2 -.->|API调用| BackSvc
    BackPod1 --> Redis
    BackPod1 --> Postgres
    BackPod2 --> Redis
    BackPod2 --> Postgres
    BackPod3 --> Redis
    BackPod3 --> Postgres

    ConfigMap -.->|挂载| FrontPod1
    ConfigMap -.->|挂载| BackPod1
    Secret -.->|挂载| BackPod1

    style User fill:#e1f5fe
    style Ingress fill:#fff3cd
    style FrontSvc fill:#e8f5e9
    style BackSvc fill:#e8f5e9
    style Redis fill:#fce4ec
    style Postgres fill:#fce4ec
```

## 部署流程

```mermaid
sequenceDiagram
    participant Dev as 开发者
    participant Git as Git仓库
    participant CI as CI/CD
    participant Reg as 镜像仓库
    participant K8s as Kubernetes
    participant App as 应用

    Dev->>Git: 推送代码
    Git->>CI: 触发构建
    CI->>CI: 运行测试
    CI->>CI: 构建镜像
    CI->>Reg: 推送镜像
    CI->>K8s: 更新部署
    K8s->>Reg: 拉取镜像
    K8s->>App: 创建/更新Pod
    App-->>Dev: 部署完成通知
```

## 组件规格

### 1. Frontend Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: demo-app
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: frontend
      tier: presentation
  template:
    metadata:
      labels:
        app: frontend
        tier: presentation
        version: v1.0.0
    spec:
      containers:
      - name: frontend
        image: demo-app/frontend:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: API_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: api.url
        - name: ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 2. Backend Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: demo-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: backend
      tier: api
  template:
    metadata:
      labels:
        app: backend
        tier: api
        version: v1.0.0
    spec:
      containers:
      - name: backend
        image: demo-app/backend:latest
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: db.host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: db.name
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: redis.url
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 8080
          initialDelaySeconds: 45
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: app-config
```

### 3. Nginx Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: demo-app
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
```

## 资源配置

```mermaid
pie title "资源分配 (总计: 20GB)"
    "Control Plane" : 4
    "Frontend Pods" : 1
    "Backend Pods" : 2
    "Database" : 2
    "Redis" : 1
    "Ingress" : 1
    "Monitoring" : 2
    "系统预留" : 7
```

## 健康检查流程

```mermaid
graph TD
    Start[开始健康检查] --> LivenessCheck{Liveness<br/>探针}

    LivenessCheck -->|成功| ReadinessCheck{Readiness<br/>探针}
    LivenessCheck -->|失败| RestartPod[重启 Pod]

    ReadinessCheck -->|成功| AddToService[加入服务<br/>负载均衡]
    ReadinessCheck -->|失败| RemoveFromService[移出服务<br/>负载均衡]

    RestartPod --> Start
    RemoveFromService --> Wait[等待恢复]
    Wait --> ReadinessCheck

    AddToService --> Healthy[Pod 健康<br/>接收流量]

    style Healthy fill:#c8e6c9
    style RestartPod fill:#ffcdd2
```

## 配置管理

### ConfigMap 结构

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: demo-app
data:
  # 前端配置
  api.url: "http://backend-service:8080"
  environment: "development"

  # 后端配置
  db.host: "postgres-service"
  db.name: "demo_app"
  db.port: "5432"
  redis.url: "redis://redis-service:6379"

  # 应用配置
  log.level: "info"
  max.connections: "100"
  timeout.seconds: "30"

  # Nginx 配置
  nginx.conf: |
    server {
        listen 80;
        server_name demo.local;

        location / {
            proxy_pass http://frontend-service:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api {
            proxy_pass http://backend-service:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
```

### Secret 管理

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: demo-app
type: Opaque
data:
  username: ZGVtb3VzZXI=  # base64: demouser
  password: ZGVtb3Bhc3M=  # base64: demopass
```

## 部署验证

### 验证步骤

```mermaid
graph LR
    Deploy[部署应用] --> CheckPods{Pods 运行?}
    CheckPods -->|是| CheckService{Service 正常?}
    CheckPods -->|否| Debug1[查看 Pod 日志]

    CheckService -->|是| CheckIngress{Ingress 配置?}
    CheckService -->|否| Debug2[检查 Endpoints]

    CheckIngress -->|是| TestAccess{访问测试}
    CheckIngress -->|否| Debug3[检查 Ingress 规则]

    TestAccess -->|成功| Success[部署成功]
    TestAccess -->|失败| Debug4[检查网络策略]

    Debug1 --> Fix[修复问题]
    Debug2 --> Fix
    Debug3 --> Fix
    Debug4 --> Fix
    Fix --> Deploy

    style Success fill:#c8e6c9
    style Fix fill:#fff3cd
```

### 验证脚本

```bash
#!/bin/bash
# 应用部署验证脚本

NAMESPACE="demo-app"

echo "🔍 验证应用部署状态..."

# 1. 检查 Namespace
echo "1️⃣ 检查 Namespace..."
kubectl get namespace $NAMESPACE

# 2. 检查 Deployments
echo "2️⃣ 检查 Deployments..."
kubectl get deployments -n $NAMESPACE

# 3. 检查 Pods
echo "3️⃣ 检查 Pods..."
kubectl get pods -n $NAMESPACE

# 4. 检查 Services
echo "4️⃣ 检查 Services..."
kubectl get services -n $NAMESPACE

# 5. 检查 Ingress
echo "5️⃣ 检查 Ingress..."
kubectl get ingress -n $NAMESPACE

# 6. 测试应用访问
echo "6️⃣ 测试应用访问..."
curl -s http://localhost:30000/ | head -n 5
curl -s http://localhost:30000/api/health

# 7. 查看资源使用
echo "7️⃣ 资源使用情况..."
kubectl top pods -n $NAMESPACE

echo "✅ 验证完成!"
```

## 故障恢复

```mermaid
stateDiagram-v2
    [*] --> 正常运行

    正常运行 --> Pod故障: Pod 崩溃
    Pod故障 --> 自动重启: kubelet 检测
    自动重启 --> 正常运行: 恢复成功
    自动重启 --> 人工介入: 重启失败

    正常运行 --> 节点故障: Node 宕机
    节点故障 --> Pod迁移: Scheduler 调度
    Pod迁移 --> 正常运行: 迁移成功

    正常运行 --> 配置错误: ConfigMap 更新
    配置错误 --> 回滚部署: kubectl rollback
    回滚部署 --> 正常运行: 回滚成功

    人工介入 --> 问题诊断
    问题诊断 --> 修复措施
    修复措施 --> 正常运行
```

## 性能基准

| 组件 | 指标 | 目标值 | 告警阈值 |
|------|------|--------|----------|
| Frontend | 响应时间 | <100ms | >500ms |
| Backend API | 响应时间 | <200ms | >1000ms |
| Backend API | QPS | 1000 | <100 |
| Database | 连接数 | <80 | >95 |
| Redis | 内存使用 | <80% | >90% |
| Pod | CPU使用率 | <70% | >85% |
| Pod | 内存使用率 | <80% | >90% |

## 扩缩容策略

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: demo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 总结

此契约定义了完整的 nginx+golang+前端 应用栈在 Kubernetes 上的部署规范，包括：

- ✅ 完整的三层架构设计
- ✅ 详细的资源配置和限制
- ✅ 健康检查和自愈机制
- ✅ 配置和密钥管理
- ✅ 部署验证和故障恢复
- ✅ 性能监控和自动扩缩容

遵循此契约可确保应用在资源受限的 macOS 环境中稳定运行，同时为生产部署做好准备。