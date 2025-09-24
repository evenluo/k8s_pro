#!/bin/bash

# Docker 基础实验验证脚本
# 配套 docker-basics.yaml 使用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 全局变量
SUCCESS_COUNT=0
TOTAL_TESTS=0
FAILED_TESTS=()

# 测试函数模板
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TOTAL_TESTS++))
    log_info "执行测试: $test_name"

    if $test_function; then
        log_success "$test_name ✅"
        ((SUCCESS_COUNT++))
    else
        log_error "$test_name ❌"
        FAILED_TESTS+=("$test_name")
    fi
    echo ""
}

# 检查 Docker 环境
check_docker_environment() {
    # 检查 Docker 命令是否可用
    if ! command -v docker &> /dev/null; then
        log_error "Docker 命令未找到，请确保 Docker 已正确安装"
        return 1
    fi

    # 检查 Docker 服务是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行，请启动 Docker Desktop"
        return 1
    fi

    # 显示 Docker 版本信息
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    log_info "Docker 版本: $docker_version"

    # 检查系统资源
    if command -v free &> /dev/null; then
        local available_mem=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
        log_info "可用内存: ${available_mem}GB"
    fi

    return 0
}

# 测试 1: 基本容器操作
test_basic_container_operations() {
    log_info "测试基本容器操作..."

    # 运行 hello-world 容器
    if docker run --rm hello-world | grep -q "Hello from Docker"; then
        log_info "Hello World 容器运行成功"
    else
        log_error "Hello World 容器运行失败"
        return 1
    fi

    # 运行交互式容器（非交互模式测试）
    local container_id=$(docker run -d ubuntu:20.04 sleep 10)
    if [ $? -eq 0 ]; then
        log_info "Ubuntu 容器创建成功: $container_id"
        # 清理容器
        docker rm -f $container_id > /dev/null
    else
        log_error "Ubuntu 容器创建失败"
        return 1
    fi

    return 0
}

# 测试 2: Web 服务和端口映射
test_web_service_and_port_mapping() {
    log_info "测试 Web 服务和端口映射..."

    # 启动 nginx 容器
    local nginx_container="test-nginx-$$"
    docker run -d --name $nginx_container -p 8080:80 nginx:alpine > /dev/null

    if [ $? -ne 0 ]; then
        log_error "Nginx 容器启动失败"
        return 1
    fi

    # 等待容器启动
    sleep 3

    # 测试端口访问
    if curl -s --max-time 10 http://localhost:8080 | grep -q "Welcome to nginx"; then
        log_info "端口映射测试成功"
    else
        log_error "端口映射测试失败，无法访问 nginx 服务"
        docker rm -f $nginx_container > /dev/null
        return 1
    fi

    # 测试容器修改
    docker exec $nginx_container sh -c 'echo "<h1>Test Modified</h1>" > /usr/share/nginx/html/index.html'
    sleep 1

    if curl -s http://localhost:8080 | grep -q "Test Modified"; then
        log_info "容器内容修改测试成功"
    else
        log_warning "容器内容修改测试失败"
    fi

    # 清理容器
    docker rm -f $nginx_container > /dev/null
    return 0
}

# 测试 3: 数据卷持久化
test_volume_persistence() {
    log_info "测试数据卷持久化..."

    local volume_name="test-volume-$$"
    local test_data="Persistent test data - $(date)"

    # 创建数据卷
    docker volume create $volume_name > /dev/null
    if [ $? -ne 0 ]; then
        log_error "数据卷创建失败"
        return 1
    fi

    # 第一个容器写入数据
    docker run --rm -v $volume_name:/data alpine sh -c "echo '$test_data' > /data/test.txt" > /dev/null
    if [ $? -ne 0 ]; then
        log_error "数据写入失败"
        docker volume rm $volume_name > /dev/null
        return 1
    fi

    # 第二个容器读取数据
    local read_data=$(docker run --rm -v $volume_name:/data alpine cat /data/test.txt)
    if [ "$read_data" = "$test_data" ]; then
        log_info "数据持久化测试成功"
    else
        log_error "数据持久化测试失败，数据不一致"
        docker volume rm $volume_name > /dev/null
        return 1
    fi

    # 清理数据卷
    docker volume rm $volume_name > /dev/null
    return 0
}

# 测试 4: 镜像构建
test_image_building() {
    log_info "测试镜像构建..."

    local build_dir="test-build-$$"
    local image_name="test-image-$$"

    # 创建构建目录
    mkdir -p $build_dir

    # 创建 Dockerfile
    cat > $build_dir/Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Custom image test" > /app/test.txt
WORKDIR /app
CMD ["cat", "test.txt"]
EOF

    # 构建镜像
    if docker build -t $image_name $build_dir > /dev/null 2>&1; then
        log_info "镜像构建成功"
    else
        log_error "镜像构建失败"
        rm -rf $build_dir
        return 1
    fi

    # 运行构建的镜像
    local output=$(docker run --rm $image_name)
    if [ "$output" = "Custom image test" ]; then
        log_info "自定义镜像运行成功"
    else
        log_error "自定义镜像运行失败"
        docker rmi $image_name > /dev/null
        rm -rf $build_dir
        return 1
    fi

    # 清理
    docker rmi $image_name > /dev/null
    rm -rf $build_dir
    return 0
}

# 测试 5: 网络通信
test_network_communication() {
    log_info "测试容器网络通信..."

    local network_name="test-network-$$"
    local server_container="server-$$"

    # 创建自定义网络
    docker network create $network_name > /dev/null
    if [ $? -ne 0 ]; then
        log_error "网络创建失败"
        return 1
    fi

    # 启动服务端容器
    docker run -d --name $server_container --network $network_name nginx:alpine > /dev/null
    if [ $? -ne 0 ]; then
        log_error "服务端容器启动失败"
        docker network rm $network_name > /dev/null
        return 1
    fi

    # 等待容器启动
    sleep 3

    # 测试容器间通信
    if docker run --rm --network $network_name alpine wget -qO- http://$server_container | grep -q "Welcome to nginx"; then
        log_info "容器间网络通信成功"
    else
        log_error "容器间网络通信失败"
        docker rm -f $server_container > /dev/null
        docker network rm $network_name > /dev/null
        return 1
    fi

    # 清理资源
    docker rm -f $server_container > /dev/null
    docker network rm $network_name > /dev/null
    return 0
}

# 测试 6: 资源限制
test_resource_limits() {
    log_info "测试资源限制..."

    # 创建内存限制容器
    local container_name="memory-test-$$"
    docker run -d --name $container_name --memory=128m alpine sleep 30 > /dev/null

    if [ $? -eq 0 ]; then
        # 检查内存限制设置
        local memory_limit=$(docker inspect $container_name --format='{{.HostConfig.Memory}}')
        if [ "$memory_limit" = "134217728" ]; then # 128MB in bytes
            log_info "内存限制设置成功"
        else
            log_warning "内存限制设置可能不正确"
        fi

        docker rm -f $container_name > /dev/null
    else
        log_error "内存限制容器创建失败"
        return 1
    fi

    return 0
}

# 清理函数
cleanup_test_resources() {
    log_info "清理测试资源..."

    # 清理可能残留的容器
    local test_containers=$(docker ps -aq --filter "name=test-" --filter "name=server-" 2>/dev/null)
    if [ ! -z "$test_containers" ]; then
        docker rm -f $test_containers > /dev/null 2>&1
    fi

    # 清理测试网络
    local test_networks=$(docker network ls --filter "name=test-network-" --format "{{.Name}}" 2>/dev/null)
    if [ ! -z "$test_networks" ]; then
        echo "$test_networks" | xargs docker network rm > /dev/null 2>&1
    fi

    # 清理测试数据卷
    local test_volumes=$(docker volume ls --filter "name=test-volume-" --format "{{.Name}}" 2>/dev/null)
    if [ ! -z "$test_volumes" ]; then
        echo "$test_volumes" | xargs docker volume rm > /dev/null 2>&1
    fi

    # 清理测试镜像
    local test_images=$(docker images --filter "reference=test-image-*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null)
    if [ ! -z "$test_images" ]; then
        echo "$test_images" | xargs docker rmi > /dev/null 2>&1
    fi

    # 清理构建目录
    rm -rf test-build-* 2>/dev/null
}

# 生成报告
generate_report() {
    echo ""
    echo "=================================="
    echo "       Docker 实验验证报告"
    echo "=================================="
    echo ""

    echo "📊 测试统计:"
    echo "   总测试数: $TOTAL_TESTS"
    echo "   成功数: $SUCCESS_COUNT"
    echo "   失败数: $((TOTAL_TESTS - SUCCESS_COUNT))"
    echo "   成功率: $(( SUCCESS_COUNT * 100 / TOTAL_TESTS ))%"
    echo ""

    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo "❌ 失败的测试:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "   - $test"
        done
        echo ""
    fi

    if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
        echo "🎉 恭喜！所有测试都通过了！"
        echo "✅ Docker 基础实验验证成功"
        return 0
    else
        echo "⚠️  部分测试失败，请检查 Docker 配置并重试失败的操作"
        echo "💡 建议查看实验指南中的故障排查部分"
        return 1
    fi
}

# 主函数
main() {
    echo "🚀 开始 Docker 基础实验验证..."
    echo ""

    # 设置清理陷阱
    trap cleanup_test_resources EXIT

    # 检查 Docker 环境
    if ! check_docker_environment; then
        log_error "Docker 环境检查失败，请解决环境问题后重试"
        exit 1
    fi
    echo ""

    # 执行测试
    run_test "基本容器操作" "test_basic_container_operations"
    run_test "Web服务和端口映射" "test_web_service_and_port_mapping"
    run_test "数据卷持久化" "test_volume_persistence"
    run_test "镜像构建" "test_image_building"
    run_test "网络通信" "test_network_communication"
    run_test "资源限制" "test_resource_limits"

    # 生成报告
    generate_report
    exit $?
}

# 帮助信息
show_help() {
    cat << EOF
Docker 基础实验验证脚本

用法: $0 [选项]

选项:
    -h, --help          显示帮助信息
    -c, --cleanup-only  仅执行清理操作
    -v, --verbose       详细输出模式

示例:
    $0                  # 运行所有测试
    $0 --cleanup-only   # 仅清理测试资源
    $0 --verbose        # 详细模式运行测试

注意:
    - 请确保 Docker Desktop 正在运行
    - 脚本会自动清理测试过程中创建的资源
    - 如果测试失败，请检查 Docker 配置
EOF
}

# 命令行参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--cleanup-only)
            cleanup_test_resources
            log_success "清理完成"
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 运行主程序
main