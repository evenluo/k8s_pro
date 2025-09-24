[TOC]

# Kubernetes 核心技能实践评估 (Core Skills Practical Assessment)

## 评估概述

本评估将全面测试您在 Kubernetes 核心课程中学到的知识和技能。您需要独立部署一个完整的多层 Web 应用，包括前端、后端 API、数据库和缓存层，并实现生产级别的配置管理、服务暴露和运维操作。

## 学习成果验证

通过本评估，将验证您是否能够：
- 🎯 独立设计和部署多层应用架构
- ⚙️ 熟练使用 Deployment、Service、ConfigMap、Secret
- 🔧 实现应用配置管理和环境隔离
- 🌐 配置服务发现和负载均衡
- 📊 进行应用扩缩容和滚动更新
- 🛠️ 排查和解决常见部署问题

## 评估要求

### 📋 基础要求
- ✅ Kind 集群运行正常（至少2个工作节点）
- ✅ 完成前置课程学习和实验
- ✅ 具备独立操作能力
- ✅ 理解 YAML 配置和 kubectl 命令

### ⏰ 时间限制
- **总时长**: 2小时
- **准备阶段**: 15分钟（环境检查和需求分析）
- **实现阶段**: 90分钟（应用部署和配置）
- **验证阶段**: 15分钟（功能测试和问题排查）

### 📊 评分标准
- **应用部署** (40分): 各层服务正确部署并运行
- **配置管理** (20分): 配置外部化和安全管理
- **网络服务** (20分): 服务发现和负载均衡
- **运维操作** (10分): 扩缩容和更新操作
- **故障排查** (10分): 问题诊断和解决能力

## 应用架构要求

您需要部署以下多层应用架构：

```mermaid
graph TB
    subgraph "多层应用架构"
        subgraph "前端层 (Frontend Tier)"
            WEB[Web 前端<br/>nginx + static files<br/>3 replicas]
        end

        subgraph "API 层 (API Tier)"
            API1[API 服务 1<br/>Node.js/Python<br/>2 replicas]
            API2[API 服务 2<br/>用户认证<br/>2 replicas]
        end

        subgraph "数据层 (Data Tier)"
            DB[数据库<br/>PostgreSQL<br/>1 replica]
            CACHE[缓存<br/>Redis<br/>1 replica]
        end

        subgraph "外部访问"
            USER[用户请求] --> INGRESS[Ingress/NodePort]
            INGRESS --> WEB
        end

        subgraph "配置管理"
            CM[ConfigMap<br/>应用配置]
            SECRET[Secret<br/>数据库密钥]
        end
    end

    WEB --> API1
    WEB --> API2
    API1 --> DB
    API1 --> CACHE
    API2 --> DB
    API2 --> CACHE

    CM --> WEB
    CM --> API1
    CM --> API2
    SECRET --> API1
    SECRET --> API2
    SECRET --> DB
    SECRET --> CACHE

    style WEB fill:#e1f5fe
    style API1 fill:#e8f5e8
    style API2 fill:#e8f5e8
    style DB fill:#fff3e0
    style CACHE fill:#f3e5f5
    style CM fill:#fce4ec
    style SECRET fill:#ffcdd2
```

## 详细任务要求

### 任务 1: 环境准备和命名空间 (5分)

**要求**:
1. 创建名为 `webapp-prod` 的命名空间
2. 为命名空间添加适当的标签和注解
3. 设置资源配额限制：
   - CPU 请求总量: 2核
   - 内存请求总量: 4Gi
   - Pod 数量上限: 20个

**验收标准**:
```bash
# 验证命令
kubectl get namespace webapp-prod --show-labels
kubectl describe resourcequota -n webapp-prod
```

### 任务 2: 数据库层部署 (10分)

**要求**:
1. 部署 PostgreSQL 数据库：
   - 使用 `postgres:13-alpine` 镜像
   - 配置持久化存储 (2Gi)
   - 设置数据库名称、用户名、密码
   - 配置健康检查

2. 部署 Redis 缓存：
   - 使用 `redis:6-alpine` 镜像
   - 配置认证密码
   - 设置内存限制

**验收标准**:
```bash
# 数据库连接测试
kubectl exec -n webapp-prod <postgres-pod> -- psql -h localhost -U <user> -d <database> -c "SELECT version();"

# Redis 连接测试
kubectl exec -n webapp-prod <redis-pod> -- redis-cli -a <password> ping
```

### 任务 3: API 层部署 (15分)

**要求**:
1. 部署主 API 服务：
   - 使用现成的镜像或创建简单的 HTTP 服务
   - 2个副本，配置反亲和性
   - 连接数据库和缓存
   - 配置环境变量和配置文件

2. 部署认证 API 服务：
   - 独立的认证服务
   - 2个副本
   - 配置 JWT 密钥等敏感信息

**验收标准**:
```bash
# API 健康检查
curl -s http://<api-service>/health
curl -s http://<auth-service>/health
```

### 任务 4: 前端层部署 (10分)

**要求**:
1. 部署 Nginx 前端服务：
   - 3个副本，分布在不同节点
   - 自定义 HTML 页面显示应用信息
   - 配置代理转发到 API 层
   - 配置静态文件缓存

**验收标准**:
```bash
# 前端访问测试
curl -s http://<frontend-service>/
curl -s http://<frontend-service>/api/health
```

### 任务 5: 配置管理 (10分)

**要求**:
1. 创建 ConfigMap 存储：
   - 应用配置参数
   - Nginx 配置文件
   - API 服务配置

2. 创建 Secret 存储：
   - 数据库连接凭据
   - Redis 认证密码
   - JWT 签名密钥

**验收标准**:
```bash
# 配置验证
kubectl get configmap,secret -n webapp-prod
kubectl exec -n webapp-prod <pod> -- env | grep -E "(DB_|REDIS_|JWT_)"
```

### 任务 6: 服务发现和负载均衡 (15分)

**要求**:
1. 为每个层创建适当的 Service：
   - PostgreSQL: ClusterIP Service
   - Redis: ClusterIP Service
   - API 服务: ClusterIP Service
   - 认证服务: ClusterIP Service
   - 前端: NodePort Service (端口 30080)

2. 配置服务发现：
   - 使用 DNS 名称进行服务间通信
   - 测试跨服务连接

**验收标准**:
```bash
# 服务访问测试
kubectl get svc -n webapp-prod
curl -s http://localhost:30080/  # 外部访问
kubectl exec -n webapp-prod <pod> -- nslookup api-service.webapp-prod.svc.cluster.local
```

### 任务 7: 应用扩缩容 (5分)

**要求**:
1. 将前端服务扩容到5个副本
2. 将主 API 服务缩容到1个副本
3. 配置一个服务的 HPA (水平自动扩缩容)

**验收标准**:
```bash
# 扩缩容验证
kubectl get deployment -n webapp-prod
kubectl get hpa -n webapp-prod
```

### 任务 8: 滚动更新 (5分)

**要求**:
1. 更新前端服务的镜像版本
2. 监控更新过程
3. 验证更新后的功能

**验收标准**:
```bash
# 更新历史查看
kubectl rollout history deployment/<deployment-name> -n webapp-prod
kubectl rollout status deployment/<deployment-name> -n webapp-prod
```

### 任务 9: 故障排查 (5分)

**要求**:
1. 模拟一个配置错误（如错误的数据库连接串）
2. 诊断问题原因
3. 修复问题并验证

**验收标准**:
- 能够快速定位问题
- 正确使用 kubectl 诊断命令
- 成功修复并恢复服务

## 实施指导

### 第一阶段：环境准备 (15分钟)

```bash
# 1. 检查集群状态
kubectl cluster-info
kubectl get nodes -o wide

# 2. 创建评估目录
mkdir -p ~/k8s-assessment
cd ~/k8s-assessment

# 3. 创建命名空间和基础资源
cat > namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: webapp-prod
  labels:
    environment: production
    purpose: assessment
    project: webapp
  annotations:
    description: "Multi-tier web application for assessment"
    contact: "student@example.com"

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: webapp-quota
  namespace: webapp-prod
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "20"
    persistentvolumeclaims: "5"
    services: "10"
    secrets: "10"
    configmaps: "10"
EOF

kubectl apply -f namespace.yaml
```

### 第二阶段：数据层实现 (20分钟)

```bash
# PostgreSQL 数据库配置示例
cat > database.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
  namespace: webapp-prod
type: Opaque
stringData:
  POSTGRES_DB: webapp
  POSTGRES_USER: webapp_user
  POSTGRES_PASSWORD: secure_password_123
  DATABASE_URL: postgresql://webapp_user:secure_password_123@postgres:5432/webapp

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp-prod
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: webapp-prod
  labels:
    app: postgres
    tier: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: database-secret
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - webapp_user
            - -d
            - webapp
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - webapp_user
            - -d
            - webapp
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: webapp-prod
  labels:
    app: postgres
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres
EOF

# 部署数据库
kubectl apply -f database.yaml
```

### 第三阶段：应用层实现 (40分钟)

参考实现思路：

1. **API 服务**: 可以使用简单的 HTTP 服务器镜像 (如 `httpd`, `nginx`) 配置静态响应
2. **前端服务**: 使用 `nginx` 配置反向代理
3. **配置管理**: 创建包含所有配置的 ConfigMap 和 Secret

### 第四阶段：测试验证 (15分钟)

```bash
# 创建验证脚本
cat > verify-deployment.sh << 'EOF'
#!/bin/bash

echo "🧪 多层应用部署验证"
echo "==================="

NS="webapp-prod"

echo "1. 检查命名空间和资源配额"
kubectl get namespace $NS --show-labels
kubectl describe resourcequota -n $NS

echo ""
echo "2. 检查所有 Pod 状态"
kubectl get pods -n $NS -o wide

echo ""
echo "3. 检查服务状态"
kubectl get svc -n $NS

echo ""
echo "4. 检查配置资源"
kubectl get configmap,secret -n $NS

echo ""
echo "5. 测试数据库连接"
DB_POD=$(kubectl get pods -n $NS -l app=postgres -o jsonpath='{.items[0].metadata.name}')
if [ -n "$DB_POD" ]; then
    kubectl exec -n $NS $DB_POD -- pg_isready -U webapp_user -d webapp
else
    echo "❌ 数据库 Pod 未找到"
fi

echo ""
echo "6. 测试 Redis 连接"
REDIS_POD=$(kubectl get pods -n $NS -l app=redis -o jsonpath='{.items[0].metadata.name}')
if [ -n "$REDIS_POD" ]; then
    kubectl exec -n $NS $REDIS_POD -- redis-cli ping
else
    echo "❌ Redis Pod 未找到"
fi

echo ""
echo "7. 测试前端访问"
if kubectl get svc -n $NS | grep -q NodePort; then
    NODE_PORT=$(kubectl get svc -n $NS -o jsonpath='{.items[?(@.spec.type=="NodePort")].spec.ports[0].nodePort}')
    echo "尝试访问 http://localhost:$NODE_PORT"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:$NODE_PORT/ || echo "连接失败"
else
    echo "❌ 未找到 NodePort 服务"
fi

echo ""
echo "8. 检查副本数量"
kubectl get deployment -n $NS -o custom-columns="NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas"

echo ""
echo "9. 检查资源使用情况"
kubectl top pods -n $NS 2>/dev/null || echo "Metrics Server 未安装"

echo ""
echo "✅ 验证完成"
EOF

chmod +x verify-deployment.sh
./verify-deployment.sh
```

## 评分细则

### 🏆 优秀 (90-100分)
- 所有服务正确部署并运行稳定
- 配置管理完善，安全措施到位
- 服务间通信正常，负载均衡有效
- 运维操作熟练，故障排查能力强
- 代码结构清晰，遵循最佳实践

### 🎯 良好 (80-89分)
- 核心功能正常，少量非关键问题
- 配置基本正确，个别安全细节欠缺
- 服务通信基本正常
- 能完成基本运维操作
- 代码结构较好

### ✅ 合格 (70-79分)
- 主要功能可用，存在一些问题
- 配置基本可用，安全考虑不足
- 部分服务间通信存在问题
- 运维操作需要指导
- 代码结构需要改进

### ⚠️ 需要改进 (60-69分)
- 部分功能不可用
- 配置错误较多
- 服务间通信存在重大问题
- 运维操作不熟练
- 代码结构混乱

### ❌ 不合格 (<60分)
- 应用无法正常运行
- 配置严重错误
- 服务无法通信
- 不能独立完成基本操作

## 常见问题和提示

### 🔧 故障排查技巧

```bash
# 1. Pod 问题诊断
kubectl get pods -n webapp-prod
kubectl describe pod <pod-name> -n webapp-prod
kubectl logs <pod-name> -n webapp-prod

# 2. 服务连接问题
kubectl get svc -n webapp-prod
kubectl get endpoints -n webapp-prod
kubectl exec -n webapp-prod <pod> -- nslookup <service-name>

# 3. 配置问题检查
kubectl get configmap <cm-name> -n webapp-prod -o yaml
kubectl get secret <secret-name> -n webapp-prod -o yaml

# 4. 资源问题
kubectl describe node
kubectl top pods -n webapp-prod
kubectl describe resourcequota -n webapp-prod
```

### 💡 实用提示

1. **分步骤验证**: 每完成一层就测试一次
2. **使用标签**: 为资源添加适当的标签便于管理
3. **配置外部化**: 避免硬编码配置信息
4. **健康检查**: 为所有服务配置健康检查
5. **资源限制**: 合理设置资源请求和限制
6. **安全考虑**: 使用 Secret 存储敏感信息

### 🚀 加分项

- 使用 Ingress 控制器而不是 NodePort
- 配置网络策略限制服务间通信
- 实现配置的动态更新
- 添加监控和日志收集
- 使用 Kustomize 管理配置

## 提交要求

### 📁 提交内容

1. **YAML 配置文件**: 所有部署的资源配置
2. **验证脚本**: 功能测试和验证脚本
3. **架构说明**: 简要的架构设计说明
4. **问题记录**: 遇到的问题和解决方案

### 📝 提交格式

```
assessment-submission/
├── manifests/
│   ├── namespace.yaml
│   ├── database.yaml
│   ├── api.yaml
│   ├── frontend.yaml
│   ├── configmap.yaml
│   └── secrets.yaml
├── scripts/
│   ├── deploy.sh
│   ├── verify.sh
│   └── cleanup.sh
├── docs/
│   ├── architecture.md
│   └── troubleshooting.md
└── README.md
```

### ⏰ 提交时间

- **截止时间**: 评估开始后 2 小时
- **验收方式**: 现场演示 + 代码审查
- **答辩时间**: 10 分钟口述和问答

## 学习建议

### 📚 复习重点

1. **Kubernetes 架构**: Master/Worker 组件和功能
2. **核心资源**: Pod、Deployment、Service、ConfigMap、Secret
3. **kubectl 命令**: 创建、查看、调试、更新操作
4. **YAML 配置**: 资源定义和最佳实践
5. **网络模型**: 服务发现、负载均衡、端口映射
6. **故障排查**: 常见问题诊断和解决方法

### 🛠️ 练习建议

1. 多次完整部署练习
2. 熟悉各种 kubectl 命令
3. 练习问题诊断流程
4. 理解服务间通信机制
5. 掌握配置管理最佳实践

### 📖 参考资源

- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [kubectl 速查表](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [课程实验文档](../labs/)
- [核心组件指南](../02-核心组件/README.md)

---

**评估成功标准**: 能够独立完成多层应用的部署、配置和运维，展现出对 Kubernetes 核心概念的扎实理解和实际操作能力。

**祝您评估顺利！** 🎉