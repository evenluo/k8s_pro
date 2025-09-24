#!/bin/bash

# Kind 集群管理脚本
# 用于创建、删除、重启和管理 Kind 集群

set -e

# 集群配置
CLUSTER_NAME="learn-k8s"
CONFIG_FILE="$(dirname "$0")/kind-config.yaml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# 显示帮助信息
show_help() {
    echo "Kind 集群管理工具"
    echo ""
    echo "使用方式: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  create    创建新集群"
    echo "  delete    删除集群"
    echo "  restart   重启集群"
    echo "  status    查看集群状态"
    echo "  load      加载镜像到集群"
    echo "  export    导出 kubeconfig"
    echo "  dashboard 安装 Kubernetes Dashboard"
    echo "  ingress   安装 Ingress Controller"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 create           # 创建集群"
    echo "  $0 status           # 查看状态"
    echo "  $0 load nginx:latest # 加载镜像"
}

# 检查依赖
check_dependencies() {
    local missing=0

    if ! command -v kind &> /dev/null; then
        print_error "Kind 未安装，请运行: brew install kind"
        missing=1
    fi

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装，请运行: brew install kubectl"
        missing=1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker 未运行，请启动 Docker Desktop"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# 创建集群
create_cluster() {
    print_info "创建 Kind 集群: $CLUSTER_NAME"

    # 检查集群是否已存在
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "集群 '$CLUSTER_NAME' 已存在"
        read -p "是否删除并重建? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_cluster
        else
            exit 0
        fi
    fi

    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "配置文件不存在: $CONFIG_FILE"
        exit 1
    fi

    # 检查内存
    check_memory

    # 创建集群
    print_info "使用配置文件: $CONFIG_FILE"
    if kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG_FILE"; then
        print_success "集群创建成功!"

        # 设置 kubectl 上下文
        kubectl cluster-info --context "kind-$CLUSTER_NAME"

        # 等待节点就绪
        print_info "等待节点就绪..."
        kubectl wait --for=condition=ready node --all --timeout=60s

        # 显示节点信息
        echo ""
        kubectl get nodes

        # 提示后续步骤
        echo ""
        print_success "集群已就绪!"
        echo "使用以下命令切换到集群上下文:"
        echo "  kubectl config use-context kind-$CLUSTER_NAME"
        echo ""
        echo "可选：安装附加组件:"
        echo "  $0 dashboard  # 安装 Dashboard"
        echo "  $0 ingress    # 安装 Ingress"
    else
        print_error "集群创建失败"
        exit 1
    fi
}

# 删除集群
delete_cluster() {
    print_info "删除 Kind 集群: $CLUSTER_NAME"

    if kind delete cluster --name "$CLUSTER_NAME"; then
        print_success "集群删除成功"
    else
        print_error "集群删除失败"
        exit 1
    fi
}

# 重启集群
restart_cluster() {
    print_info "重启集群: $CLUSTER_NAME"

    # 停止容器
    docker stop $(docker ps -q --filter "label=io.x-k8s.kind.cluster=$CLUSTER_NAME") 2>/dev/null || true

    # 启动容器
    docker start $(docker ps -aq --filter "label=io.x-k8s.kind.cluster=$CLUSTER_NAME") 2>/dev/null || true

    # 等待 API Server
    print_info "等待 API Server 就绪..."
    sleep 5

    if kubectl cluster-info --context "kind-$CLUSTER_NAME" &> /dev/null; then
        print_success "集群重启成功"
        status_cluster
    else
        print_error "集群重启失败"
        exit 1
    fi
}

# 查看集群状态
status_cluster() {
    print_info "集群状态: $CLUSTER_NAME"
    echo ""

    # 检查集群是否存在
    if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "集群不存在"
        return
    fi

    # 显示节点状态
    echo "节点状态:"
    kubectl get nodes --context "kind-$CLUSTER_NAME" 2>/dev/null || print_error "无法连接到集群"

    # 显示 Pod 状态
    echo ""
    echo "系统 Pod 状态:"
    kubectl get pods -n kube-system --context "kind-$CLUSTER_NAME" 2>/dev/null | head -10

    # 显示资源使用
    echo ""
    echo "资源使用情况:"
    kubectl top nodes --context "kind-$CLUSTER_NAME" 2>/dev/null || print_info "Metrics Server 未安装"
}

# 加载镜像到集群
load_image() {
    local image=$1

    if [ -z "$image" ]; then
        print_error "请指定镜像名称"
        echo "示例: $0 load nginx:latest"
        exit 1
    fi

    print_info "加载镜像到集群: $image"

    # 检查镜像是否存在
    if ! docker image inspect "$image" &> /dev/null; then
        print_info "本地不存在镜像，正在拉取..."
        docker pull "$image"
    fi

    # 加载到 Kind 集群
    if kind load docker-image "$image" --name "$CLUSTER_NAME"; then
        print_success "镜像加载成功: $image"
    else
        print_error "镜像加载失败"
        exit 1
    fi
}

# 导出 kubeconfig
export_kubeconfig() {
    local output_file="${1:-kubeconfig.yaml}"

    print_info "导出 kubeconfig 到: $output_file"

    if kind get kubeconfig --name "$CLUSTER_NAME" > "$output_file"; then
        print_success "kubeconfig 导出成功"
        echo "使用方式: export KUBECONFIG=$(pwd)/$output_file"
    else
        print_error "导出失败"
        exit 1
    fi
}

# 安装 Dashboard
install_dashboard() {
    print_info "安装 Kubernetes Dashboard..."

    # 安装 Dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

    # 创建管理员用户
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

    print_success "Dashboard 安装成功!"
    echo ""
    echo "访问 Dashboard:"
    echo "1. 运行代理: kubectl proxy"
    echo "2. 访问: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    echo "获取登录令牌:"
    echo "kubectl -n kubernetes-dashboard create token admin-user"
}

# 安装 Ingress Controller
install_ingress() {
    print_info "安装 NGINX Ingress Controller..."

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    print_info "等待 Ingress Controller 就绪..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s

    print_success "Ingress Controller 安装成功!"
    echo "Ingress 已配置端口映射:"
    echo "  HTTP:  http://localhost"
    echo "  HTTPS: https://localhost"
}

# 检查内存
check_memory() {
    local docker_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
    local memory_gb=$((docker_memory / 1073741824))

    if [ $memory_gb -lt 8 ]; then
        print_warning "Docker 内存分配: ${memory_gb}GB (建议 ≥8GB)"
        print_info "请调整 Docker Desktop 内存设置"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Docker 内存分配: ${memory_gb}GB"
    fi
}

# 主函数
main() {
    local command=${1:-help}

    # 检查依赖（除了 help 命令）
    if [ "$command" != "help" ]; then
        check_dependencies
    fi

    case $command in
        create)
            create_cluster
            ;;
        delete)
            delete_cluster
            ;;
        restart)
            restart_cluster
            ;;
        status)
            status_cluster
            ;;
        load)
            load_image "$2"
            ;;
        export)
            export_kubeconfig "$2"
            ;;
        dashboard)
            install_dashboard
            ;;
        ingress)
            install_ingress
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"