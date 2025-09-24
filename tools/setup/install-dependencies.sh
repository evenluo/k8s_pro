#!/bin/bash

# Kubernetes 学习环境依赖安装脚本 (macOS)
# 用于设置本地 K8s 学习和开发环境
# 要求: macOS 10.15+ 和 Homebrew

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# 检查操作系统
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "此脚本仅支持 macOS"
        exit 1
    fi
    print_success "检测到 macOS 系统"
}

# 检查并安装 Homebrew
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_error "未找到 Homebrew"
        print_info "请先安装 Homebrew: https://brew.sh"
        exit 1
    fi
    print_success "Homebrew 已安装 ($(brew --version | head -n 1))"
}

# 检查并安装 Docker Desktop
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker 已安装 ($(docker --version))"
    else
        print_info "正在安装 Docker Desktop..."
        brew install --cask docker
        print_success "Docker Desktop 已安装"
        print_info "请启动 Docker Desktop 并分配至少 8GB 内存"
        print_info "设置路径: Docker Desktop → Preferences → Resources → Memory"
    fi
}

# 检查并安装 kubectl
install_kubectl() {
    if command -v kubectl &> /dev/null; then
        print_success "kubectl 已安装 ($(kubectl version --client --short 2>/dev/null || kubectl version --client -o yaml | grep gitVersion | head -1))"
    else
        print_info "正在安装 kubectl..."
        brew install kubectl
        print_success "kubectl 已安装"
    fi
}

# 检查并安装 Kind
install_kind() {
    if command -v kind &> /dev/null; then
        print_success "Kind 已安装 ($(kind version))"
    else
        print_info "正在安装 Kind (Kubernetes in Docker)..."
        brew install kind
        print_success "Kind 已安装"
    fi
}

# 检查并安装 Helm
install_helm() {
    if command -v helm &> /dev/null; then
        print_success "Helm 已安装 ($(helm version --short))"
    else
        print_info "正在安装 Helm..."
        brew install helm
        print_success "Helm 已安装"
    fi
}

# 检查并安装 Go (用于项目实战)
install_golang() {
    if command -v go &> /dev/null; then
        print_success "Go 已安装 ($(go version))"
    else
        print_info "正在安装 Go..."
        brew install go
        print_success "Go 已安装"
        echo "export PATH=\$PATH:\$(go env GOPATH)/bin" >> ~/.zshrc
        print_info "请运行 'source ~/.zshrc' 更新 PATH"
    fi
}

# 检查并安装 Node.js (用于前端项目)
install_nodejs() {
    if command -v node &> /dev/null; then
        print_success "Node.js 已安装 ($(node --version))"
    else
        print_info "正在安装 Node.js..."
        brew install node
        print_success "Node.js 已安装"
    fi
}

# 安装额外的有用工具
install_extras() {
    print_info "安装额外工具..."

    # k9s - Kubernetes CLI 管理工具
    if ! command -v k9s &> /dev/null; then
        brew install k9s
        print_success "k9s (K8s CLI UI) 已安装"
    else
        print_success "k9s 已存在"
    fi

    # jq - JSON 处理工具
    if ! command -v jq &> /dev/null; then
        brew install jq
        print_success "jq (JSON 处理器) 已安装"
    else
        print_success "jq 已存在"
    fi

    # yq - YAML 处理工具
    if ! command -v yq &> /dev/null; then
        brew install yq
        print_success "yq (YAML 处理器) 已安装"
    else
        print_success "yq 已存在"
    fi
}

# 验证 Docker 运行状态
verify_docker() {
    print_info "验证 Docker 状态..."
    if docker info &> /dev/null; then
        print_success "Docker 正在运行"

        # 检查内存分配
        local memory=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
        local memory_gb=$((memory / 1073741824))

        if [ $memory_gb -lt 8 ]; then
            print_error "Docker 内存分配不足 (当前: ${memory_gb}GB, 建议: ≥8GB)"
            print_info "请调整 Docker Desktop 内存设置"
        else
            print_success "Docker 内存分配充足 (${memory_gb}GB)"
        fi
    else
        print_error "Docker 未运行，请启动 Docker Desktop"
        return 1
    fi
}

# 创建配置文件
create_configs() {
    print_info "创建配置文件..."

    # 创建 kubectl 配置目录
    mkdir -p ~/.kube
    print_success "kubectl 配置目录已创建"

    # 设置 kubectl 自动补全
    if ! grep -q "kubectl completion zsh" ~/.zshrc 2>/dev/null; then
        echo 'source <(kubectl completion zsh)' >> ~/.zshrc
        print_success "kubectl 自动补全已配置"
    fi
}

# 打印安装摘要
print_summary() {
    echo ""
    echo "======================================"
    echo "   Kubernetes 学习环境安装完成"
    echo "======================================"
    echo ""
    echo "已安装组件:"
    echo "  • Docker Desktop"
    echo "  • kubectl - Kubernetes CLI"
    echo "  • Kind - 本地 K8s 集群"
    echo "  • Helm - K8s 包管理器"
    echo "  • Go - 后端开发"
    echo "  • Node.js - 前端开发"
    echo "  • k9s - K8s CLI UI"
    echo "  • jq/yq - JSON/YAML 工具"
    echo ""
    echo "下一步:"
    echo "  1. 确保 Docker Desktop 正在运行"
    echo "  2. 分配至少 8GB 内存给 Docker"
    echo "  3. 运行 tools/validation/check-environment.sh 验证环境"
    echo "  4. 开始学习 courses/00-foundation/"
    echo ""
}

# 主函数
main() {
    echo "======================================"
    echo "  Kubernetes 学习环境安装脚本"
    echo "======================================"
    echo ""

    check_os
    check_homebrew

    print_info "开始安装必要组件..."
    echo ""

    install_docker
    install_kubectl
    install_kind
    install_helm
    install_golang
    install_nodejs
    install_extras

    echo ""
    create_configs

    echo ""
    if verify_docker; then
        print_summary
    else
        print_error "请启动 Docker Desktop 后重新运行验证"
        exit 1
    fi
}

# 运行主函数
main "$@"