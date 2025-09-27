[TOC]

# 安全加固指南 (Security Hardening Playbook)

## 学习目标

完成本模块后，您将能够：
- 设计覆盖 macOS 学习环境与 Linux 生产环境的一致安全基线
- 利用 RBAC、Pod Security Standards、NetworkPolicy 构建多层访问控制
- 建立镜像供应链安全与合规扫描流程，结合 GitOps 发布
- 制定安全事件响应与合规审计步骤，与监控、生产实践模块协同

## 前置知识

- 熟悉 Kubernetes 基础对象与命名空间隔离策略
- 已完成 `courses/02-advanced/01-生产实践/README.md` 与 `02-监控运维/README.md`
- 掌握 `kubectl`, `kustomize`, `helm` 等命令工具
- 理解基础安全概念：最小权限、密钥管理、零信任网络

## 模块结构概览

| 单元 | 目标 | 关联文件 |
| --- | --- | --- |
| 安全基线评估 | 定义 macOS ↔ Linux 差异与基线控制项 | `specs/001-k8s/research.md` 平台差异 |
| RBAC & 秘钥管理 | 设计最小权限角色、ServiceAccount 策略 | `courses/02-advanced/assessment/scenario.yaml` (后续) |
| 网络隔离策略 | NetworkPolicy、Ingress/Egress 设计 | `courses/03-service-mesh/` 流量治理 |
| 镜像与供应链安全 | 签名、扫描、Registry 控制 | `tools/validation/check-environment.sh` |
| 事件响应与合规 | 审计日志、SIEM 集成、回滚流程 | `courses/02-advanced/01-生产实践/README.md` Runbook |

## 安全基线评估

### macOS 学习环境
- Kind/Colima 节点运行在轻量 Linux VM，macOS 层面缺少 SELinux/AppArmor
- 可使用 `falco` 或 `sysdig` 在 VM 内收集内核事件
- 警惕共享目录 (`docker-desktop-data`) 权限，避免将密钥放入挂载目录

### Linux 生产环境
- 启用 SELinux (Enforcing) 或 AppArmor，结合 `seccomp` 限制系统调用
- 使用 `auditd` 结合 `CloudTrail`/`GCP Audit Logs` 记录 API 调用
- 通过 `CIS Benchmark` Baselining 工具（如 `kube-bench`）持续评估控制平面配置

## RBAC 与秘钥管理

### 角色设计原则
1. **命名空间级角色优先**：使用 `Role` + `RoleBinding` 绑定团队
2. **集群级角色审慎**：`ClusterRole` 仅授予平台团队和 CI/CD Robot
3. **ServiceAccount 最小权限**：每个应用独立 ServiceAccount，不使用 `default`

### 示例：CI/CD Robot 权限
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cicd-deployer
rules:
  - apiGroups: ["apps", "batch"]
    resources: ["deployments", "statefulsets", "jobs"]
    verbs: ["get", "list", "watch", "create", "update"]
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cicd-deployer-binding
subjects:
  - kind: ServiceAccount
    name: flux
    namespace: flux-system
roleRef:
  kind: ClusterRole
  name: cicd-deployer
  apiGroup: rbac.authorization.k8s.io
```

### Secrets 管理
- macOS 学习环境使用 `kubectl create secret --from-file` 管理示例密钥
- 生产环境建议接入 `External Secrets Operator` 或 `SealedSecrets`
- 所有 Secret 在 Git 仓库中以加密形式存在；GitOps Pipeline 解密后注入集群

## 网络隔离与策略

### NetworkPolicy 模板
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              env: prod
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - ipBlock:
            cidr: 10.10.0.0/16
      ports:
        - protocol: TCP
          port: 5432
  policyTypes: [Ingress, Egress]
```

### 平台差异
- macOS Kind：NetworkPolicy 需确保 CNI 支持（推荐 `kindnet` 或 `calico` 测试版），使用 `kubectl exec` 验证连通性
- Linux 生产：结合 `Calico`/`Cilium`，启用 eBPF 日志，记录拒绝事件供 SIEM 分析

### Pod Security Standards
- 在学习环境中使用 `PodSecurity ` Admission 的 `baseline` 模式
- 生产命名空间设置为 `restricted`，禁止特权容器、宿主网络、宿主路径挂载
- 编写 `PodDisruptionBudget` 保障安全策略调整时的服务可用性

## 镜像与供应链安全

- **镜像签名**：利用 `cosign` 或 `notary` 对构建镜像签名，GitOps Pipeline 验证签名后才部署
- **漏洞扫描**：本地使用 `trivy` 或 `grype`，CI 阶段强制扫描并输出报告
- **Registry 控制**：限制仅允许来自企业私有 Registry 的镜像；结合 `ImagePolicyWebhook` 进行准入
- **依赖管理**：在 macOS 和 Linux 上统一使用 `Makefile` / `taskfile` 触发扫描，保证跨平台一致性

## 事件响应与合规

### 流程概览
1. 监控模块告警触发安全事件标签（`severity=critical`, `type=security`）
2. 生产实践 Runbook 发起安全应急会议，执行流量隔离 (`kubectl cordon`, `networkpolicy deny`)
3. 收集证据：导出 `kubectl get events`, `kubectl logs`, `audit.log`
4. 执行回滚或隔离部署，利用 GitOps 回滚安全事件前版本
5. 开展事后复盘，更新策略与文档

### 合规审计清单
- API Server 审计日志保留 ≥ 90 天
- 每季度运行 `kube-bench`, `kube-hunter`，记录整改结果
- RBAC 权限审计：使用 `kubectl get rolebinding --all-namespaces` + 脚本比对最小权限
- Secret 使用追踪：启用 `EncryptionConfiguration`，保障 etcd 中密钥加密

## 与相邻模块的协同

- **生产实践**：安全事件响应步骤与发布 Runbook 融合
- **监控运维**：在 Grafana 中加入安全仪表，如 RBAC 变更计数、NetworkPolicy 拒绝事件
- **Service Mesh**：Istio mTLS、AuthorizationPolicy 与本模块 NetworkPolicy 配合实现零信任

## 学习检验

### 自查问题
1. 如何为 CI/CD Robot 设计最小权限的 ClusterRole？
2. 在 macOS Kind 环境测试 NetworkPolicy 时需要注意哪些 CNI 限制？
3. 在 Linux 生产环境中如何实施镜像签名与验证流程？

### 实践任务
1. 在 Kind 集群创建 `allow-frontend-to-backend` NetworkPolicy，并验证不在白名单的 Pod 无法访问后台服务
2. 使用 `cosign` 为示例镜像签名，并在 Admission Webhook 中强制验证
3. 模拟安全事件：手动创建异常 ServiceAccount，触发告警后按照事件流程完成封堵与复盘记录

## 下一步学习

- **[监控与运维观测](../02-监控运维/README.md)**：结合安全指标扩展 Dashboard
- **[生产实践指南](../01-生产实践/README.md)**：复习回滚与 Runbook 流程
- **[Service Mesh 模块](../../03-service-mesh/)**：深入 Istio 安全策略，实现零信任流量控制

---

通过本模块的学习，您已掌握在有限资源下构建可执行的 Kubernetes 安全体系。请将 RBAC、网络策略、镜像签名与事件响应流程纳入团队标准，确保从 macOS 学习环境迁移至 Linux 生产环境时仍可保持安全态势可控。
