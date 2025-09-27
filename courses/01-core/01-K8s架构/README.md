[TOC]

# Kubernetes 架构 (Kubernetes Architecture)

## 学习目标

完成本模块后，您将能够：
- 理解 Kubernetes 分布式架构设计理念
- 掌握 Master 和 Worker 节点的核心组件
- 了解组件间的交互机制和数据流
- 理解 K8s 网络和存储架构模型

## 概念卡速记

> 📌 **概念卡：Control Plane（控制平面）**  
> **定义**：由 API Server、etcd、Scheduler、Controller Manager 等组件组成，负责整个集群的状态管理与调度决策。  
> **学习提醒**：控制平面高可用是生产级集群重点，理解其组件职责是后续故障排查的起点。  
> **关键命令**：`kubectl get componentstatuses`、`kubectl get nodes --selector='node-role.kubernetes.io/control-plane'`

> 📌 **概念卡：Data Plane（数据平面/工作节点）**  
> **定义**：运行应用工作负载的节点，由 kubelet、kube-proxy 与容器运行时协同工作。  
> **学习提醒**：kubelet 上报节点状态，kube-proxy 维护服务网络，两者健康度直接影响 Pod 生命周期。  
> **关键命令**：`kubectl describe node <node-name>`

> 📌 **概念卡：API Server（集群 API 服务）**  
> **定义**：控制平面核心入口，提供 RESTful API、认证授权与准入控制，是所有命令与控制器的交互枢纽。  
> **学习提醒**：排查集群问题时优先检查 API Server 日志与健康状态。  
> **关键命令**：`kubectl get --raw='/healthz'`

> 📌 **概念卡：etcd（分布式键值存储）**  
> **定义**：保存集群期望状态与配置的高一致性键值存储，支持事务与快照。  
> **学习提醒**：etcd 性能与备份策略决定集群可靠性，需掌握备份/恢复流程。  
> **关键命令**：`ETCDCTL_API=3 etcdctl snapshot save backup.db`

## 前置知识

- 容器和 Docker 基础概念
- 分布式系统基本理解
- Linux 系统和网络基础
- YAML 配置文件格式

## Kubernetes 整体架构

Kubernetes 采用 **Master-Worker** 分布式架构，通过声明式 API 管理容器化应用的生命周期。

```mermaid
graph TB
    subgraph "Kubernetes 集群架构"
        subgraph "Master 节点 (控制平面)"
            API[API Server<br/>集群入口和认证]
            ETCD[etcd<br/>分布式存储]
            SCHED[Scheduler<br/>Pod 调度器]
            CM[Controller Manager<br/>控制器管理]
            CCM[Cloud Controller<br/>云平台集成]
        end

        subgraph "Worker 节点 1 (数据平面)"
            KUBELET1[kubelet<br/>节点代理]
            PROXY1[kube-proxy<br/>网络代理]
            RUNTIME1[Container Runtime<br/>容器运行时]

            subgraph "Pod1"
                C1[Container 1]
                C2[Container 2]
            end
        end

        subgraph "Worker 节点 2 (数据平面)"
            KUBELET2[kubelet<br/>节点代理]
            PROXY2[kube-proxy<br/>网络代理]
            RUNTIME2[Container Runtime<br/>容器运行时]

            subgraph "Pod2"
                C3[Container 3]
            end
        end

        subgraph "外部组件"
            DNS[CoreDNS<br/>集群DNS]
            ADDON[Add-ons<br/>扩展组件]
        end
    end

    subgraph "用户交互"
        KUBECTL[kubectl<br/>命令行工具]
        UI[Dashboard<br/>Web界面]
        CLIENT[Client Apps<br/>应用程序]
    end

    %% 连接关系
    KUBECTL --> API
    UI --> API
    CLIENT --> API

    API <--> ETCD
    API <--> SCHED
    API <--> CM
    API <--> CCM

    SCHED --> KUBELET1
    SCHED --> KUBELET2

    KUBELET1 <--> API
    KUBELET2 <--> API

    KUBELET1 --> RUNTIME1
    KUBELET2 --> RUNTIME2

    RUNTIME1 --> Pod1
    RUNTIME2 --> Pod2

    PROXY1 -.-> Pod1
    PROXY2 -.-> Pod2

    DNS -.-> Pod1
    DNS -.-> Pod2

    %% 样式
    style API fill:#e1f5fe
    style ETCD fill:#fff3e0
    style SCHED fill:#e8f5e8
    style CM fill:#f3e5f5
    style KUBELET1 fill:#fce4ec
    style KUBELET2 fill:#fce4ec
    style Pod1 fill:#e0f2f1
    style Pod2 fill:#e0f2f1
```

## Master 节点组件 (控制平面)

Master 节点负责集群的管理和控制，包含以下核心组件：

### 🌐 API Server

**作用**: 集群的统一入口，提供 RESTful API

```mermaid
graph LR
    subgraph "API Server 功能"
        A[RESTful API<br/>资源CRUD操作]
        B[Authentication<br/>身份认证]
        C[Authorization<br/>权限授权]
        D[Admission Control<br/>准入控制]
        E[API Versioning<br/>版本管理]
    end

    subgraph "客户端"
        KUBECTL[kubectl]
        KUBELET[kubelet]
        CONTROLLER[Controllers]
        EXTERNAL[External Apps]
    end

    KUBECTL --> A
    KUBELET --> A
    CONTROLLER --> A
    EXTERNAL --> A

    A --> B --> C --> D --> E

    style A fill:#e1f5fe
    style B fill:#fff8e1
    style C fill:#f3e5f5
    style D fill:#e8f5e8
    style E fill:#fce4ec
```

**核心职责**：
- 🔐 **API 网关**: 所有集群操作的唯一入口
- 🔑 **认证授权**: 用户和组件身份验证
- 📝 **资源验证**: API 对象格式和语义检查
- 🔄 **状态同步**: 与 etcd 进行数据交互
- 📡 **事件通知**: 资源变化的 Watch 机制

**交互流程**：
1. 客户端发送 HTTP/HTTPS 请求
2. 身份认证 (Authentication)
3. 权限检查 (Authorization)
4. 准入控制 (Admission Control)
5. 资源验证和存储到 etcd
6. 返回操作结果

### 🗄️ etcd

**作用**: 分布式键值存储，集群的"数据库"

```mermaid
graph TB
    subgraph "etcd 集群"
        E1[etcd Node 1<br/>Leader]
        E2[etcd Node 2<br/>Follower]
        E3[etcd Node 3<br/>Follower]
    end

    subgraph "存储的数据类型"
        CONFIG[集群配置]
        STATE[资源状态]
        SECRETS[敏感数据]
        NETWORK[网络信息]
    end

    API[API Server] <--> E1
    E1 <--> E2
    E1 <--> E3
    E2 <--> E3

    E1 --> CONFIG
    E1 --> STATE
    E1 --> SECRETS
    E1 --> NETWORK

    style E1 fill:#fff3e0
    style E2 fill:#f5f5f5
    style E3 fill:#f5f5f5
    style API fill:#e1f5fe
```

**核心特性**：
- 🔄 **一致性**: 使用 Raft 算法保证强一致性
- 🚀 **高可用**: 支持集群部署，自动故障转移
- ⚡ **高性能**: 针对读多写少场景优化
- 🔐 **安全性**: 支持 TLS 加密和 RBAC 权限控制

**存储内容**：
- 所有 Kubernetes 资源对象 (Pod、Service、Deployment 等)
- 集群配置信息和网络拓扑
- 密钥和证书等敏感数据
- 集群状态和元数据

### 📅 Scheduler

**作用**: 负责 Pod 的调度决策，选择最合适的节点

```mermaid
graph TD
    subgraph "调度流程"
        A[新 Pod 创建] --> B[获取待调度 Pod]
        B --> C[节点过滤<br/>Filtering]
        C --> D[节点打分<br/>Scoring]
        D --> E[选择最佳节点]
        E --> F[绑定 Pod 到节点]
    end

    subgraph "调度因素"
        R1[资源要求<br/>CPU/Memory]
        R2[节点亲和性<br/>Node Affinity]
        R3[Pod 亲和性<br/>Pod Affinity]
        R4[污点容忍<br/>Taints/Tolerations]
        R5[数据局部性<br/>Data Locality]
    end

    C --> R1
    C --> R2
    C --> R3
    C --> R4
    D --> R5

    style A fill:#e8f5e8
    style E fill:#fff3e0
    style F fill:#e1f5fe
```

**调度策略**：

1. **过滤阶段 (Filtering)**：
   - 资源充足性检查 (CPU、内存、存储)
   - 端口冲突检查
   - 节点选择器匹配
   - 亲和性和反亲和性规则
   - 污点和容忍度检查

2. **打分阶段 (Scoring)**：
   - 资源均衡分布
   - 镜像拉取速度优化
   - 数据局部性考虑
   - 自定义调度策略

### ⚙️ Controller Manager

**作用**: 运行各种控制器，维护集群期望状态

```mermaid
graph TB
    subgraph "Controller Manager"
        CM[Controller Manager<br/>控制器管理器]

        subgraph "核心控制器"
            RC[Replication Controller<br/>副本控制]
            DC[Deployment Controller<br/>部署控制]
            SC[Service Controller<br/>服务控制]
            EC[Endpoint Controller<br/>端点控制]
            NC[Node Controller<br/>节点控制]
            JC[Job Controller<br/>任务控制]
        end
    end

    subgraph "控制循环"
        WATCH[监听 API Server<br/>Watch Events]
        COMPARE[对比期望状态<br/>vs 当前状态]
        RECONCILE[协调操作<br/>Reconcile]
        UPDATE[更新资源状态]
    end

    API[API Server] <--> CM
    CM --> RC
    CM --> DC
    CM --> SC
    CM --> EC
    CM --> NC
    CM --> JC

    RC --> WATCH
    WATCH --> COMPARE
    COMPARE --> RECONCILE
    RECONCILE --> UPDATE
    UPDATE --> API

    style CM fill:#f3e5f5
    style COMPARE fill:#fff3e0
    style RECONCILE fill:#e8f5e8
```

**主要控制器**：

- **Deployment Controller**: 管理 ReplicaSet 和滚动更新
- **ReplicaSet Controller**: 确保 Pod 副本数量
- **Service Controller**: 管理 Service 和 Endpoints
- **Node Controller**: 监控节点健康状态
- **Job Controller**: 管理批量任务和定时任务
- **Namespace Controller**: 处理命名空间生命周期

## Worker 节点组件 (数据平面)

Worker 节点运行实际的容器工作负载：

### 🤖 kubelet

**作用**: 节点上的 Kubernetes 代理，管理 Pod 生命周期

```mermaid
graph TD
    subgraph "kubelet 核心功能"
        A[Pod 生命周期管理]
        B[容器健康检查]
        C[资源监控上报]
        D[Volume 挂载管理]
        E[网络配置]
    end

    subgraph "交互组件"
        API[API Server]
        CRI[Container Runtime<br/>containerd/Docker]
        CNI[Network Plugin<br/>网络插件]
        CSI[Storage Plugin<br/>存储插件]
    end

    KUBELET[kubelet] --> A
    KUBELET --> B
    KUBELET --> C
    KUBELET --> D
    KUBELET --> E

    A <--> API
    A <--> CRI
    E <--> CNI
    D <--> CSI
    C --> API

    style KUBELET fill:#fce4ec
    style A fill:#e8f5e8
    style B fill:#fff3e0
    style C fill:#e1f5fe
```

**核心职责**：
- 📦 **Pod 管理**: 创建、启动、停止、删除 Pod
- 🩺 **健康检查**: 执行存活探针和就绪探针
- 📊 **资源监控**: 收集节点和 Pod 的资源使用情况
- 💾 **存储管理**: 挂载和卸载 Volume
- 🌐 **网络配置**: 配置 Pod 网络接口

### 🌐 kube-proxy

**作用**: 维护网络规则，实现 Service 的负载均衡

```mermaid
graph LR
    subgraph "Service 网络实现"
        CLIENT[Client Request] --> VIRTUAL[Virtual IP<br/>ClusterIP]
        VIRTUAL --> PROXY[kube-proxy<br/>网络规则]

        subgraph "负载均衡模式"
            IPTABLES[iptables 模式<br/>默认]
            IPVS[IPVS 模式<br/>高性能]
            USERSPACE[userspace 模式<br/>兼容性]
        end

        PROXY --> IPTABLES
        PROXY --> IPVS
        PROXY --> USERSPACE

        IPTABLES --> POD1[Pod 1:8080]
        IPTABLES --> POD2[Pod 2:8080]
        IPTABLES --> POD3[Pod 3:8080]
    end

    style VIRTUAL fill:#e1f5fe
    style PROXY fill:#f3e5f5
    style IPTABLES fill:#e8f5e8
    style POD1 fill:#e0f2f1
    style POD2 fill:#e0f2f1
    style POD3 fill:#e0f2f1
```

**实现模式**：

1. **iptables 模式** (默认)：
   - 使用 iptables 规则实现负载均衡
   - 随机或轮询分发请求
   - 适合中小规模集群

2. **IPVS 模式** (推荐)：
   - 基于 Linux 内核的 IPVS 模块
   - 支持多种负载均衡算法
   - 更好的性能和可扩展性

3. **userspace 模式** (已废弃)：
   - 早期版本的实现方式
   - 性能较差，主要用于兼容

### 🐳 Container Runtime

**作用**: 实际运行容器的底层系统

```mermaid
graph TB
    subgraph "容器运行时架构"
        subgraph "High-Level Runtime"
            CONTAINERD[containerd<br/>容器管理]
            DOCKER[Docker Engine<br/>传统方案]
            CRIO[CRI-O<br/>轻量级]
        end

        subgraph "Low-Level Runtime"
            RUNC[runc<br/>OCI 标准实现]
            KATA[Kata Containers<br/>安全容器]
            GVISOR[gVisor<br/>沙箱运行时]
        end

        subgraph "Container Runtime Interface"
            CRI[CRI API<br/>统一接口]
        end
    end

    KUBELET[kubelet] <--> CRI
    CRI <--> CONTAINERD
    CRI <--> DOCKER
    CRI <--> CRIO

    CONTAINERD --> RUNC
    DOCKER --> RUNC
    CRIO --> RUNC

    CONTAINERD -.-> KATA
    CONTAINERD -.-> GVISOR

    style CRI fill:#e1f5fe
    style CONTAINERD fill:#e8f5e8
    style RUNC fill:#fff3e0
```

**主要实现**：
- **containerd**: Cloud Native Computing Foundation 项目，Docker 的核心组件
- **CRI-O**: 专为 Kubernetes 设计的轻量级运行时
- **Docker**: 传统容器运行时，通过 dockershim 集成

## 网络架构模型

Kubernetes 网络遵循以下基本要求：

```mermaid
graph TB
    subgraph "Kubernetes 网络模型"
        subgraph "Pod 网络"
            P1[Pod 1<br/>10.244.1.10]
            P2[Pod 2<br/>10.244.1.11]
            P3[Pod 3<br/>10.244.2.10]
        end

        subgraph "Service 网络"
            SVC[ClusterIP Service<br/>10.96.0.100]
            NODEPORT[NodePort Service<br/>30080]
            LB[LoadBalancer<br/>外部IP]
        end

        subgraph "Node 网络"
            N1[Node 1<br/>192.168.1.10]
            N2[Node 2<br/>192.168.1.11]
        end

        subgraph "网络插件 CNI"
            FLANNEL[Flannel<br/>Overlay 网络]
            CALICO[Calico<br/>BGP 路由]
            WEAVE[Weave<br/>网格网络]
        end
    end

    P1 <--> P2
    P2 <--> P3
    P1 <--> P3

    SVC --> P1
    SVC --> P2
    SVC --> P3

    NODEPORT --> SVC
    LB --> NODEPORT

    N1 --> P1
    N1 --> P2
    N2 --> P3

    FLANNEL -.-> P1
    CALICO -.-> P2
    WEAVE -.-> P3

    style P1 fill:#e0f2f1
    style P2 fill:#e0f2f1
    style P3 fill:#e0f2f1
    style SVC fill:#e1f5fe
    style FLANNEL fill:#fff3e0
```

**网络要求**：
1. 🔗 **Pod 互通**: 任意两个 Pod 可以直接通信，无需 NAT
2. 🌐 **节点到 Pod**: 节点可以与所有 Pod 通信
3. 📍 **Pod 身份**: Pod 看到的自己 IP 与其他 Pod 看到的相同
4. 🔒 **网络隔离**: 支持 NetworkPolicy 进行访问控制

## 存储架构模型

```mermaid
graph TD
    subgraph "Kubernetes 存储架构"
        subgraph "存储抽象层"
            PV[PersistentVolume<br/>持久卷]
            PVC[PersistentVolumeClaim<br/>持久卷申请]
            SC[StorageClass<br/>存储类]
        end

        subgraph "卷类型"
            HOSTPATH[hostPath<br/>主机路径]
            NFS[NFS<br/>网络文件系统]
            CEPH[Ceph RBD<br/>分布式存储]
            CLOUD[云存储<br/>AWS EBS/GCP PD]
        end

        subgraph "CSI 驱动"
            CSI[Container Storage Interface<br/>存储接口标准]
            DRIVER[Storage Driver<br/>存储驱动插件]
        end

        subgraph "Pod 使用"
            VOL[Volume<br/>卷挂载]
            MOUNT[Mount Point<br/>挂载点]
        end
    end

    POD[Pod] --> VOL
    VOL --> MOUNT

    VOL <--> PVC
    PVC <--> PV
    PV <--> SC

    SC --> HOSTPATH
    SC --> NFS
    SC --> CEPH
    SC --> CLOUD

    CSI <--> DRIVER
    DRIVER <--> PV

    style PV fill:#fff3e0
    style PVC fill:#e1f5fe
    style SC fill:#e8f5e8
    style POD fill:#e0f2f1
```

## 组件通信流程

### Pod 创建完整流程

```mermaid
sequenceDiagram
    participant U as kubectl
    participant A as API Server
    participant E as etcd
    participant S as Scheduler
    participant C as Controller
    participant K as kubelet
    participant R as Container Runtime

    U->>A: 1. 创建 Deployment
    A->>E: 2. 存储 Deployment 对象
    A->>U: 3. 返回成功响应

    C->>A: 4. Watch Deployment
    C->>A: 5. 创建 ReplicaSet
    A->>E: 6. 存储 ReplicaSet

    C->>A: 7. 创建 Pod
    A->>E: 8. 存储 Pod (Pending)

    S->>A: 9. Watch 未调度 Pod
    S->>A: 10. 绑定 Pod 到节点
    A->>E: 11. 更新 Pod.spec.nodeName

    K->>A: 12. Watch 分配给本节点的 Pod
    K->>R: 13. 创建容器
    R->>K: 14. 返回容器状态
    K->>A: 15. 更新 Pod 状态
    A->>E: 16. 持久化 Pod 状态
```

### Service 访问流程

```mermaid
sequenceDiagram
    participant C as Client
    participant P as kube-proxy
    participant D as DNS (CoreDNS)
    participant S as Service
    participant Pod1
    participant Pod2

    C->>D: 1. DNS 解析 service.namespace.svc.cluster.local
    D->>C: 2. 返回 ClusterIP

    C->>P: 3. 请求 ClusterIP:Port
    P->>P: 4. iptables/IPVS 负载均衡

    alt 路由到 Pod1
        P->>Pod1: 5a. 转发请求
        Pod1->>P: 6a. 返回响应
    else 路由到 Pod2
        P->>Pod2: 5b. 转发请求
        Pod2->>P: 6b. 返回响应
    end

    P->>C: 7. 返回最终响应
```

## 高可用架构

生产环境中的高可用 Kubernetes 集群：

```mermaid
graph TB
    subgraph "高可用集群架构"
        subgraph "负载均衡层"
            LB[Load Balancer<br/>HAProxy/Nginx]
        end

        subgraph "Master 节点集群"
            M1[Master 1<br/>API Server + etcd]
            M2[Master 2<br/>API Server + etcd]
            M3[Master 3<br/>API Server + etcd]
        end

        subgraph "Worker 节点集群"
            W1[Worker 1<br/>kubelet + kube-proxy]
            W2[Worker 2<br/>kubelet + kube-proxy]
            W3[Worker 3<br/>kubelet + kube-proxy]
            W4[Worker N<br/>kubelet + kube-proxy]
        end

        subgraph "外部存储"
            ETCD_EXTERNAL[外部 etcd 集群<br/>可选独立部署]
        end
    end

    CLIENT[Clients] --> LB
    LB --> M1
    LB --> M2
    LB --> M3

    M1 <--> M2
    M2 <--> M3
    M1 <--> M3

    M1 --> W1
    M1 --> W2
    M2 --> W3
    M3 --> W4

    M1 -.-> ETCD_EXTERNAL
    M2 -.-> ETCD_EXTERNAL
    M3 -.-> ETCD_EXTERNAL

    style LB fill:#ff9800
    style M1 fill:#e1f5fe
    style M2 fill:#e1f5fe
    style M3 fill:#e1f5fe
    style W1 fill:#e8f5e8
    style W2 fill:#e8f5e8
    style W3 fill:#e8f5e8
    style W4 fill:#e8f5e8
```

**高可用要点**：
- 🔄 **多 Master**: 至少 3 个 Master 节点，奇数个避免脑裂
- 💾 **etcd 集群**: 独立的 etcd 集群或与 Master 节点混部
- ⚖️ **负载均衡**: API Server 前端负载均衡器
- 🌐 **网络冗余**: 多网络接口和路由路径
- 📊 **监控告警**: 全方位的集群健康监控

## 实际应用场景

### 1. 开发环境
- **单节点**: minikube、Kind、Docker Desktop
- **资源**: 2-4 CPU, 4-8GB 内存
- **特点**: 快速启动，功能完整，适合学习

### 2. 测试环境
- **多节点**: 3 Master + 3-5 Worker
- **资源**: 中等配置，接近生产
- **特点**: 稳定性测试，集成测试

### 3. 生产环境
- **高可用**: 3+ Master + 多 Worker
- **资源**: 高配置，充足冗余
- **特点**: 高可用、高性能、安全加固

## 常见问题和排查

### 🔍 架构相关问题

**问题 1**: API Server 无法访问
```bash
# 检查 API Server 状态
kubectl cluster-info
systemctl status kube-apiserver

# 检查证书和网络
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
netstat -tlnp | grep 6443
```

**问题 2**: etcd 数据不一致
```bash
# 检查 etcd 集群健康
kubectl exec -n kube-system etcd-master -- etcdctl cluster-health
kubectl exec -n kube-system etcd-master -- etcdctl member list

# 检查数据一致性
kubectl get events --all-namespaces
```

**问题 3**: Pod 调度失败
```bash
# 查看调度器日志
kubectl logs -n kube-system kube-scheduler-master

# 检查节点状态和资源
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes
```

## 学习检验

### 🎯 理解检查

1. **架构概念**:
   - 解释 Master-Worker 架构的优势
   - 描述控制平面和数据平面的职责分工
   - 说明 API Server 在整个架构中的作用

2. **组件交互**:
   - 绘制 Pod 创建的完整流程图
   - 解释 Service 访问的网络路径
   - 描述控制器的工作机制

3. **网络存储**:
   - 说明 K8s 网络模型的基本要求
   - 解释 CNI 插件的作用和选择
   - 描述 CSI 存储接口的价值

### ✅ 实践验证

在接下来的实验中，您将：
- 使用 Kind 搭建本地 K8s 集群
- 观察各组件的启动和交互过程
- 通过实际操作加深对架构的理解

## 下一步学习

- **[核心组件详解](../02-核心组件/README.md)**: 深入学习 Pod、Service、Deployment
- **[应用部署实践](../03-应用部署/README.md)**: 掌握 kubectl 和 YAML 配置
- **[集群搭建实验](../labs/)**: 动手搭建和管理 K8s 集群

---

通过本模块的学习，您现在应该对 Kubernetes 的整体架构有了清晰的理解。这个架构设计体现了云原生的核心理念：**声明式**、**可扩展**、**高可用**。在后续的学习中，我们将深入每个组件的具体功能和使用方法。
