# Research Document: Kubernetes Learning Curriculum

**Feature**: Kubernetes Expert Learning Curriculum
**Date**: 2025-09-24
**Context**: macOS Pro (32GB, 20GB available) learning environment for K8s mastery

## Executive Summary
This research document consolidates findings on optimal Kubernetes learning approaches for macOS users, focusing on resource-constrained local development and production-ready skills. Key decisions include using Kind for local clusters, progressive learning with Chinese content, and culminating in a nginx+golang+frontend application deployment.

## Research Areas

### 1. Kubernetes Local Development on macOS

**Decision**: Kind (Kubernetes in Docker) as primary learning tool
**Rationale**:
- Lowest resource footprint compared to alternatives
- Native Docker Desktop integration
- Supports multi-node clusters
- Easy reset/cleanup for learning iterations

**Alternatives Considered**:
- Minikube: Higher resource usage, more complex setup
- Docker Desktop K8s: Limited to single node, less production-like
- k3s/k3d: Less standard, potential compatibility issues
- MicroK8s: Not optimized for macOS

**Implementation Notes**:
```bash
# Kind cluster with resource limits
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        max-pods: "50"
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        max-pods: "50"
```

### 2. Resource Optimization for 20GB Constraint

**Decision**: Tiered cluster configurations
**Rationale**:
- Progressive resource usage as skills advance
- Leaves headroom for application workloads
- Prevents system instability

**Resource Allocation Strategy**:
```
基础阶段 (Foundation):
  - Single node: 4GB RAM
  - Docker + basic containers

核心阶段 (Core):
  - 2 nodes: 8GB RAM total
  - Control plane + 1 worker

高级阶段 (Advanced):
  - 3 nodes: 12GB RAM total
  - Control plane + 2 workers

项目阶段 (Project):
  - 3 nodes + apps: 16GB RAM total
  - Full stack deployment
```

**Alternatives Considered**:
- Single large cluster: Inefficient for early learning
- Cloud-based clusters: Latency, cost, less control
- Virtual machines: Higher overhead on macOS

### 3. nginx+golang+frontend Architecture

**Decision**: Microservices pattern with ingress controller
**Rationale**:
- Industry-standard architecture
- Demonstrates key K8s concepts
- Scalable and observable

**Architecture Components**:
```yaml
应用架构:
  Frontend:
    - React/Vue SPA
    - Nginx static serving
    - ConfigMap for environment

  Backend:
    - Golang REST API
    - Configuration via ConfigMap
    - Secrets for credentials

  Gateway:
    - Nginx Ingress Controller
    - Path-based routing
    - TLS termination

  Data:
    - Redis for session
    - PostgreSQL for persistence
    - PersistentVolumes
```

**Alternatives Considered**:
- Monolithic: Doesn't showcase K8s strengths
- Service mesh: Too complex for learning
- Serverless: Not representative of typical K8s

### 4. macOS vs Linux Production Differences

**Decision**: Dual-track explanation approach
**Rationale**:
- Clear distinction prevents confusion
- Builds transferable skills
- Acknowledges platform limitations

**Key Differences Matrix**:
| Component | macOS Practice | Linux Production |
|-----------|---------------|------------------|
| Container Runtime | Docker Desktop | containerd/CRI-O |
| Networking | vpnkit bridge | iptables/IPVS |
| Storage | Local paths | CSI drivers |
| Resource Limits | Hypervisor constrained | cgroups v2 |
| Monitoring | Limited /proc | Full system metrics |
| Security | Simplified RBAC | SELinux/AppArmor |

**Platform-Specific Tools**:
```
macOS开发工具:
  - Docker Desktop
  - Lens/k9s
  - kubectl via brew
  - stern for logs

Linux生产工具:
  - kubeadm
  - systemd integration
  - crictl
  - etcdctl
```

### 5. Chinese Learning Resources

**Decision**: Bilingual approach with Chinese primary
**Rationale**:
- Accessibility for Chinese speakers
- Technical terms remain searchable
- Aligns with community resources

**Content Strategy**:
```
标题和说明: 中文
技术术语: 保留英文
命令和代码: 英文 with 中文注释
错误信息: 原始英文 + 中文解释
```

**Quality Resources Found**:
- Kubernetes中文文档: kubernetes.io/zh
- 阿里云K8s最佳实践
- CNCF中文社区资源
- 极客时间K8s课程参考

## Technical Recommendations

### Development Environment Setup
```bash
# 必需工具安装脚本
#!/bin/bash
# macOS Kubernetes 学习环境设置

# 1. 安装 Homebrew (如未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安装 Docker Desktop
brew install --cask docker

# 3. 安装 Kubernetes 工具
brew install kubectl kind helm k9s stern

# 4. 安装开发工具
brew install go node yarn
brew install --cask visual-studio-code

# 5. 配置 shell 自动补全
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'source <(kind completion zsh)' >> ~/.zshrc
```

### Learning Path Validation
Each module should include validation scripts:
```yaml
验证检查点:
  环境检查:
    - Docker daemon运行状态
    - kubectl配置验证
    - 集群连接测试

  部署验证:
    - Pod运行状态
    - Service可访问性
    - Ingress路由测试

  应用检查:
    - 健康检查端点
    - 性能基准测试
    - 日志聚合验证
```

## Risk Mitigation

### Potential Issues & Solutions

**内存不足**:
- Solution: 提供内存优化配置
- Fallback: 云端沙箱环境链接

**Docker Desktop限制**:
- Solution: 明确标注企业版功能
- Alternative: Colima作为备选

**网络访问问题**:
- Solution: 镜像加速器配置
- Backup: 离线镜像包提供

**版本兼容性**:
- Solution: 锁定版本矩阵
- Practice: 定期更新验证

## Conclusion

The research confirms feasibility of comprehensive K8s learning on macOS with 20GB RAM constraint. Key success factors:

1. **工具选择**: Kind provides best balance of features and resources
2. **渐进式学习**: Progressive resource allocation matches skill development
3. **实战项目**: nginx+golang+frontend demonstrates real-world patterns
4. **双轨教学**: Clear macOS/Linux distinction prevents confusion
5. **中文优先**: Accessible content with technical accuracy

## Next Steps

Phase 1 Design will create:
- Detailed course data model
- Module learning contracts
- Lab validation frameworks
- Quick start guide
- Progress tracking system

All research findings integrated into curriculum design to ensure practical, effective K8s mastery path.