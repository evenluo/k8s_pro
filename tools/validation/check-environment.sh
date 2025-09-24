#!/bin/bash

# Kubernetes 学习环境验证脚本
# 基于 contracts/environment-validation.yaml 的验证规则
# 验证系统环境、Docker、Kubernetes工具和集群状态

set -e

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 结果统计
PASSED=0
FAILED=0
WARNINGS=0

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}    $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}$(printf '%.0s-' {1..40})${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "  ${CYAN}→${NC} $1"
}

# 验证函数
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major_version=$(echo $version | cut -d. -f1)
    local minor_version=$(echo $version | cut -d. -f2)

    if [[ $major_version -ge 11 ]] || [[ $major_version -eq 10 && $minor_version -ge 15 ]]; then
        print_success "macOS 版本: $version (满足 ≥11.0 要求)"
    else
        print_error "macOS 版本: $version (需要 ≥11.0)"
        return 1
    fi
}

check_memory() {
    local total_memory_bytes=$(sysctl -n hw.memsize)
    local total_memory_gb=$((total_memory_bytes / 1024 / 1024 / 1024))

    if [[ $total_memory_gb -ge 20 ]]; then
        print_success "系统内存: ${total_memory_gb}GB (满足 ≥20GB 要求)"
    else
        print_warning "系统内存: ${total_memory_gb}GB (建议 ≥20GB，当前可能需要优化)"
    fi

    # 显示内存分配建议
    print_info "建议内存分配:"
    print_info "  Docker Desktop: 8-12GB"
    print_info "  Kind 集群: 4-8GB"
    print_info "  应用程序: 2-4GB"
    print_info "  系统保留: 4GB"
}

check_cpu_arch() {
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]] || [[ "$arch" == "arm64" ]]; then
        print_success "CPU 架构: $arch (支持)"
    else
        print_error "CPU 架构: $arch (不支持，需要 x86_64 或 arm64)"
        return 1
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker Desktop 未安装"
        print_info "请运行: brew install --cask docker"
        return 1
    fi

    # 检查 Docker 版本
    if docker version &> /dev/null; then
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
        if [[ -z "$docker_version" ]]; then
            print_error "Docker Desktop 未运行"
            print_info "请启动 Docker Desktop 应用"
            return 1
        fi

        # 比较版本号
        local major_version=$(echo $docker_version | cut -d. -f1)
        if [[ $major_version -ge 20 ]]; then
            print_success "Docker 版本: $docker_version (满足 ≥20.10 要求)"
        else
            print_warning "Docker 版本: $docker_version (建议升级到 20.10+)"
        fi

        # 检查内存配置
        local docker_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null)
        if [[ -n "$docker_memory" ]]; then
            local memory_gb=$((docker_memory / 1073741824))
            if [[ $memory_gb -ge 8 ]]; then
                print_success "Docker 内存配置: ${memory_gb}GB (满足 ≥8GB 要求)"
            else
                print_error "Docker 内存配置: ${memory_gb}GB (需要 ≥8GB)"
                print_info "调整路径: Docker Desktop → Preferences → Resources → Memory"
            fi
        fi
    else
        print_error "Docker Desktop 未运行"
        print_info "请启动 Docker Desktop 应用"
        return 1
    fi
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装"
        print_info "请运行: brew install kubectl"
        return 1
    fi

    local kubectl_version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo "unknown")
    if [[ "$kubectl_version" == v1.* ]]; then
        local minor_version=$(echo $kubectl_version | cut -d. -f2)
        if [[ $minor_version -ge 25 ]]; then
            print_success "kubectl 版本: $kubectl_version (满足 ≥v1.25 要求)"
        else
            print_warning "kubectl 版本: $kubectl_version (建议升级到 v1.25+)"
        fi
    else
        print_warning "kubectl 版本: $kubectl_version"
    fi
}

check_kind() {
    if ! command -v kind &> /dev/null; then
        print_error "Kind 未安装"
        print_info "请运行: brew install kind"
        return 1
    fi

    local kind_version=$(kind version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    print_success "Kind 已安装: $kind_version"
}

check_helm() {
    if ! command -v helm &> /dev/null; then
        print_warning "Helm 未安装 (可选)"
        print_info "建议运行: brew install helm"
    else
        local helm_version=$(helm version --short 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "unknown")
        if [[ "$helm_version" == v3.* ]]; then
            print_success "Helm 已安装: $helm_version"
        else
            print_warning "Helm 版本: $helm_version (建议使用 v3.x)"
        fi
    fi
}

check_development_tools() {
    # Go 语言检查
    if ! command -v go &> /dev/null; then
        print_warning "Go 未安装 (项目实战需要)"
        print_info "建议运行: brew install go"
    else
        local go_version=$(go version | awk '{print $3}')
        print_success "Go 已安装: $go_version"
    fi

    # Node.js 检查
    if ! command -v node &> /dev/null; then
        print_warning "Node.js 未安装 (前端项目需要)"
        print_info "建议运行: brew install node"
    else
        local node_version=$(node --version)
        print_success "Node.js 已安装: $node_version"
    fi

    # 辅助工具检查
    if command -v k9s &> /dev/null; then
        print_success "k9s 已安装 (Kubernetes CLI UI)"
    else
        print_info "可选: brew install k9s (提供更好的集群管理界面)"
    fi

    if command -v jq &> /dev/null; then
        print_success "jq 已安装 (JSON 处理工具)"
    else
        print_info "建议: brew install jq (用于处理 JSON 输出)"
    fi
}

check_kind_cluster() {
    local cluster_name="learn-k8s"

    if kind get clusters 2>/dev/null | grep -q "$cluster_name"; then
        print_success "Kind 集群 '$cluster_name' 存在"

        # 检查集群连接
        if kubectl cluster-info --context "kind-$cluster_name" &> /dev/null; then
            print_success "可以连接到集群 'kind-$cluster_name'"

            # 检查节点状态
            local nodes_ready=$(kubectl get nodes --context "kind-$cluster_name" -o json 2>/dev/null | \
                jq '[.items[].status.conditions[] | select(.type=="Ready").status] | all(. == "True")' 2>/dev/null || echo "false")

            if [[ "$nodes_ready" == "true" ]]; then
                print_success "所有节点已就绪"

                # 显示节点信息
                print_info "集群节点信息:"
                kubectl get nodes --context "kind-$cluster_name" 2>/dev/null | while read line; do
                    print_info "  $line"
                done
            else
                print_warning "部分节点未就绪"
            fi
        else
            print_error "无法连接到集群 'kind-$cluster_name'"
            print_info "请检查集群配置或重新创建集群"
        fi
    else
        print_info "Kind 集群 '$cluster_name' 未创建"
        print_info "可以稍后使用 'kind create cluster --name $cluster_name' 创建"
    fi
}

show_resource_optimization() {
    print_section "资源优化建议"

    echo -e "\n${CYAN}内存优化:${NC}"
    print_info "使用轻量级镜像 (如 alpine) - 节省 30-50% 内存"
    print_info "设置资源限制 - 防止内存溢出"
    print_info "定期清理: docker system prune -a"

    echo -e "\n${CYAN}性能优化:${NC}"
    print_info "开发环境使用 1-2 个副本"
    print_info "使用本地存储避免网络延迟"
    print_info "禁用不必要的 admission webhooks"
}

show_summary() {
    print_header "验证摘要"

    echo -e "\n${GREEN}通过: $PASSED${NC}"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}警告: $WARNINGS${NC}"
    fi
    if [[ $FAILED -gt 0 ]]; then
        echo -e "${RED}失败: $FAILED${NC}"
    fi

    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✅ 环境验证通过！${NC}"
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}   存在一些可选改进项，但不影响基本使用${NC}"
        fi
        echo -e "\n下一步:"
        echo "1. 如果尚未运行安装脚本: ./tools/setup/install-dependencies.sh"
        echo "2. 创建 Kind 集群: kind create cluster --name learn-k8s --config tools/setup/kind-config.yaml"
        echo "3. 开始学习: courses/00-foundation/"
    else
        echo -e "\n${RED}❌ 环境验证失败${NC}"
        echo -e "   请先解决上述错误，然后重新运行验证"
        echo -e "\n建议:"
        echo "1. 运行安装脚本: ./tools/setup/install-dependencies.sh"
        echo "2. 按照错误提示进行修复"
        echo "3. 重新运行此验证脚本"
    fi
}

# 主函数
main() {
    print_header "Kubernetes 学习环境验证"
    echo "基于 contracts/environment-validation.yaml"
    echo "验证时间: $(date '+%Y-%m-%d %H:%M:%S')"

    # Stage 1: 系统基础要求
    print_section "Stage 1: 系统基础要求"
    check_macos_version
    check_memory
    check_cpu_arch

    # Stage 2: Docker 环境
    print_section "Stage 2: Docker 环境"
    check_docker

    # Stage 3: Kubernetes 工具
    print_section "Stage 3: Kubernetes 工具"
    check_kubectl
    check_kind
    check_helm

    # Stage 4: 开发工具 (可选)
    print_section "Stage 4: 开发工具"
    check_development_tools

    # Stage 5: 集群验证
    print_section "Stage 5: 集群验证"
    check_kind_cluster

    # 资源优化建议
    if [[ $WARNINGS -gt 0 ]] || [[ $FAILED -gt 0 ]]; then
        show_resource_optimization
    fi

    # 显示摘要
    show_summary

    # 返回状态码
    if [[ $FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# 运行主函数
main "$@"