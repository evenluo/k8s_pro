# Quick Start Guide: Kubernetes 学习之旅

## 🚀 30分钟快速体验

通过这个快速指南，您将在30分钟内搭建环境并部署第一个Kubernetes应用。

## 学习路径总览

```mermaid
graph LR
    Start([开始]) --> Env[环境搭建<br/>10分钟]
    Env --> Docker[Docker体验<br/>5分钟]
    Docker --> K8s[K8s集群<br/>10分钟]
    K8s --> Deploy[部署应用<br/>5分钟]
    Deploy --> Success([成功!])

    style Start fill:#e1f5fe
    style Success fill:#c8e6c9
```

## Step 1: 环境准备 (10分钟)

### 系统要求检查

```mermaid
graph TD
    Check[系统检查] --> macOS{macOS版本}
    macOS -->|11.0+| RAM{内存检查}
    macOS -->|<11.0| Upgrade[需要升级]

    RAM -->|32GB| Storage{存储空间}
    RAM -->|<32GB| Warning[性能警告]

    Storage -->|20GB+| Docker{Docker Desktop}
    Storage -->|<20GB| Clean[清理空间]

    Docker -->|已安装| Ready[环境就绪]
    Docker -->|未安装| Install[安装Docker]

    Install --> Ready

    style Ready fill:#c8e6c9
    style Warning fill:#fff3cd
    style Upgrade fill:#f8d7da
```

### 快速安装脚本

```bash
#!/bin/bash
# 保存为 setup.sh 并执行

echo "🔧 开始配置 Kubernetes 学习环境..."

# 1. 检查并安装 Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. 安装必需工具
echo "🛠️ 安装 Kubernetes 工具..."
brew install kubectl kind helm k9s

# 3. 验证安装
echo "✅ 验证安装..."
kubectl version --client
kind version
helm version

echo "🎉 环境配置完成!"
```

## Step 2: Docker 初体验 (5分钟)

### 运行第一个容器

```mermaid
sequenceDiagram
    participant U as 用户
    participant D as Docker Desktop
    participant C as Container
    participant I as Image

    U->>D: docker run hello-world
    D->>I: 检查本地镜像
    I-->>D: 镜像不存在
    D->>I: 拉取 hello-world:latest
    I-->>D: 下载完成
    D->>C: 创建并运行容器
    C-->>U: Hello from Docker!
```

执行命令：
```bash
# 1. 运行 hello-world
docker run hello-world

# 2. 查看运行的容器
docker ps -a

# 3. 运行交互式容器
docker run -it alpine sh
```

## Step 3: 创建 K8s 集群 (10分钟)

### Kind 集群架构

```mermaid
graph TB
    subgraph "macOS Host"
        Docker[Docker Desktop]

        subgraph "Kind Cluster"
            CP[Control Plane<br/>API Server<br/>etcd<br/>Scheduler<br/>Controller]
            W1[Worker Node 1<br/>kubelet<br/>kube-proxy]
            W2[Worker Node 2<br/>kubelet<br/>kube-proxy]

            CP -.-> W1
            CP -.-> W2
        end
    end

    kubectl[kubectl CLI] --> CP

    style Docker fill:#e3f2fd
    style CP fill:#fff3cd
    style W1 fill:#f5f5f5
    style W2 fill:#f5f5f5
```

### 创建集群配置

创建文件 `kind-config.yaml`:
```yaml
# Kind cluster 配置 - 适合 20GB 内存限制
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000
        protocol: TCP
  - role: worker
  - role: worker
```

### 启动集群

```bash
# 1. 创建集群
kind create cluster --config kind-config.yaml --name learn-k8s

# 2. 验证集群状态
kubectl cluster-info
kubectl get nodes

# 3. 使用 k9s 查看集群
k9s
```

## Step 4: 部署第一个应用 (5分钟)

### 应用部署流程

```mermaid
graph TD
    subgraph "部署流程"
        YAML[编写 YAML] --> Apply[kubectl apply]
        Apply --> Deploy[创建 Deployment]
        Deploy --> RS[创建 ReplicaSet]
        RS --> Pod1[Pod 1]
        RS --> Pod2[Pod 2]
        RS --> Pod3[Pod 3]

        Service[创建 Service] --> LB[负载均衡]
        LB --> Pod1
        LB --> Pod2
        LB --> Pod3
    end

    User[用户访问] --> Service

    style User fill:#e1f5fe
    style Service fill:#fff3cd
```

### 部署 Nginx 应用

创建文件 `nginx-app.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30000
```

### 部署和访问

```bash
# 1. 部署应用
kubectl apply -f nginx-app.yaml

# 2. 查看部署状态
kubectl get deployments
kubectl get pods
kubectl get services

# 3. 访问应用
open http://localhost:30000

# 4. 查看日志
kubectl logs -l app=nginx

# 5. 扩缩容
kubectl scale deployment nginx-deployment --replicas=5
```

## 验证检查清单

```mermaid
graph LR
    subgraph "环境验证 ✓"
        E1[Docker运行中]
        E2[kubectl已配置]
        E3[Kind集群活跃]
    end

    subgraph "基础技能 ✓"
        S1[运行容器]
        S2[创建集群]
        S3[部署应用]
    end

    subgraph "进阶准备 ➡"
        A1[理解Pod概念]
        A2[Service原理]
        A3[资源管理]
    end

    E1 --> S1
    E2 --> S2
    E3 --> S3
    S3 --> A1
    S3 --> A2
    S3 --> A3
```

## 🎯 恭喜完成！

您已经成功：
- ✅ 搭建了 Kubernetes 学习环境
- ✅ 创建了本地 K8s 集群
- ✅ 部署了第一个应用
- ✅ 学会了基础 kubectl 命令

## 下一步学习

```mermaid
timeline
    title Kubernetes 学习路线图

    section 基础阶段
        Docker深入     : 容器镜像, 网络, 存储
        K8s概念        : Pod, Service, Deployment
        YAML编写       : 资源定义, 标签选择器

    section 核心阶段
        应用管理       : ConfigMap, Secret, Volume
        网络深入       : Ingress, NetworkPolicy
        存储方案       : PV, PVC, StorageClass

    section 高级阶段
        生产实践       : RBAC, 资源限制, 亲和性
        监控日志       : Prometheus, Grafana, ELK
        CI/CD         : GitOps, Helm, ArgoCD

    section 项目实战
        架构设计       : 微服务拆分, API网关
        完整部署       : nginx+golang+前端
        运维管理       : 故障恢复, 性能优化
```

## 常见问题排查

### 问题诊断流程

```mermaid
graph TD
    Problem[遇到问题] --> Type{问题类型}

    Type -->|Pod无法启动| CheckPod[kubectl describe pod]
    Type -->|服务无法访问| CheckSvc[kubectl get endpoints]
    Type -->|集群问题| CheckCluster[kind get clusters]

    CheckPod --> Logs[kubectl logs]
    CheckSvc --> Port[检查端口映射]
    CheckCluster --> Recreate[重建集群]

    Logs --> Solution[查看错误信息]
    Port --> Solution
    Recreate --> Solution

    Solution --> Fixed[问题解决]

    style Problem fill:#f8d7da
    style Fixed fill:#c8e6c9
```

## 学习资源

- 📚 [Kubernetes 中文文档](https://kubernetes.io/zh/)
- 🎥 [视频教程播放列表](./resources/videos.md)
- 💬 [学习社区讨论组](./resources/community.md)
- 🔧 [工具和脚本集合](./tools/)

---

准备好深入学习了吗？继续前往 [基础课程](../../courses/00-foundation/) 📖