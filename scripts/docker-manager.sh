#!/bin/bash

# ==============================================================================
# Docker Manager Script for Online-Time Project
# ==============================================================================
# 
# A comprehensive script to manage all Docker operations for the project.
# This script provides a unified interface for building, running, and managing
# Docker containers for development, testing, and production.
#
# Usage:
#   ./scripts/docker-manager.sh <command> [options]
#
# Commands:
#   build       Build Docker images
#   run         Run containers
#   push        Push images to registry
#   dev         Start development environment
#   test        Run tests in containers
#   clean       Clean up Docker resources
#   status      Show container status
#   logs        Show container logs
#   health      Check container health
#
# ==============================================================================

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source configuration
source "$SCRIPT_DIR/docker-config.sh"

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $*"; }
log_header() { echo -e "${BOLD}${CYAN}$*${NC}"; }

# Global options
VERBOSE=false
DRY_RUN=false
ENVIRONMENT="production"
TAG="latest"

show_help() {
    cat << EOF
Docker Manager for Online-Time Project

USAGE:
    $0 <command> [options]

COMMANDS:
    build [OPTIONS]         Build Docker images
      --prod                Build production image
      --dev                 Build development image  
      --multi-arch          Build for multiple architectures
      --no-cache            Build without cache
      
    run [OPTIONS]          Run containers
      --prod                Run production container
      --dev                 Run development container
      --detach              Run in background
      --port PORT           Specify port mapping
      
    push [OPTIONS]         Push images to registry
      --tag TAG             Specify image tag
      --latest              Also push as latest
      
    dev                    Start development environment
    test [OPTIONS]         Run tests in containers
      --coverage            Run with coverage
      --watch               Run in watch mode
      
    clean [OPTIONS]        Clean up Docker resources
      --images              Remove images
      --containers          Remove containers
      --volumes             Remove volumes
      --all                 Remove everything
      
    status                 Show container status
    logs [SERVICE]         Show container logs
    health                 Check container health
    shell [SERVICE]        Open shell in container

GLOBAL OPTIONS:
    --verbose              Enable verbose output
    --dry-run              Show what would be done
    --env ENV              Set environment (dev|test|prod)
    --tag TAG              Set image tag
    -h, --help             Show this help

EXAMPLES:
    # Build and run production container
    $0 build --prod
    $0 run --prod --port 3000

    # Start development environment
    $0 dev

    # Run tests with coverage
    $0 test --coverage

    # Clean up everything
    $0 clean --all

    # Push multi-architecture build
    $0 build --multi-arch --tag v1.0.0
    $0 push --tag v1.0.0 --latest

EOF
}

# =============================================================================
# Command Functions
# =============================================================================

cmd_build() {
    local prod=false
    local dev=false
    local multi_arch=false
    local no_cache=false
    local dockerfile="$DOCKERFILE_PATH"
    local target=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prod) prod=true; shift ;;
            --dev) dev=true; dockerfile="docker/dev/Dockerfile"; target="development"; shift ;;
            --multi-arch) multi_arch=true; shift ;;
            --no-cache) no_cache=true; shift ;;
            *) log_error "Unknown build option: $1"; exit 1 ;;
        esac
    done
    
    log_header "Building Docker Image"
    log_info "Environment: $ENVIRONMENT"
    log_info "Dockerfile: $dockerfile"
    
    local build_args=()
    build_args+=("--file" "$dockerfile")
    build_args+=("--tag" "$(get_full_image_name "$DEFAULT_IMAGE_NAME" "$TAG")")
    
    if [[ "$target" != "" ]]; then
        build_args+=("--target" "$target")
    fi
    
    if [[ "$no_cache" == "true" ]]; then
        build_args+=("--no-cache")
    fi
    
    if [[ "$multi_arch" == "true" ]]; then
        log_info "Using multi-architecture build script..."
        exec "$SCRIPT_DIR/build-and-push.sh" --build-only --tag "$TAG"
    else
        log_info "Building single architecture image..."
        docker build "${build_args[@]}" "$BUILD_CONTEXT"
    fi
    
    log_success "Build completed"
}

cmd_run() {
    local prod=false
    local dev=false
    local detach=false
    local port="3000:80"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prod) prod=true; shift ;;
            --dev) dev=true; port="5173:5173"; shift ;;
            --detach) detach=true; shift ;;
            --port) port="$2"; shift 2 ;;
            *) log_error "Unknown run option: $1"; exit 1 ;;
        esac
    done
    
    local image_name="$(get_full_image_name "$DEFAULT_IMAGE_NAME" "$TAG")"
    local container_name="online-time-${ENVIRONMENT}"
    
    log_header "Running Container"
    log_info "Image: $image_name"
    log_info "Port mapping: $port"
    
    # Stop existing container if running
    if docker ps -q --filter "name=$container_name" | grep -q .; then
        log_info "Stopping existing container..."
        docker stop "$container_name" || true
        docker rm "$container_name" || true
    fi
    
    local run_args=()
    run_args+=("--name" "$container_name")
    run_args+=("--port" "$port")
    run_args+=("--env" "NODE_ENV=$ENVIRONMENT")
    
    if [[ "$detach" == "true" ]]; then
        run_args+=("--detach")
    fi
    
    if [[ "$dev" == "true" ]]; then
        run_args+=("--volume" "$PROJECT_ROOT:/app")
        run_args+=("--volume" "/app/node_modules")
    fi
    
    docker run "${run_args[@]}" "$image_name"
    
    if [[ "$detach" == "true" ]]; then
        log_success "Container started in background"
        log_info "Access at: http://localhost:$(echo "$port" | cut -d: -f1)"
    fi
}

cmd_push() {
    local tag_specified=false
    local push_latest=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tag) TAG="$2"; tag_specified=true; shift 2 ;;
            --latest) push_latest=true; shift ;;
            *) log_error "Unknown push option: $1"; exit 1 ;;
        esac
    done
    
    log_header "Pushing Docker Image"
    exec "$SCRIPT_DIR/build-and-push.sh" --tag "$TAG" "$@"
}

cmd_dev() {
    log_header "Starting Development Environment"
    
    # Check if development image exists
    local dev_image="$(get_full_image_name "$DEFAULT_IMAGE_NAME" "dev")"
    
    if ! docker image inspect "$dev_image" &>/dev/null; then
        log_info "Development image not found, building..."
        cmd_build --dev
    fi
    
    # Start development environment with docker-compose
    log_info "Starting development services..."
    docker-compose --profile dev up -d
    
    log_success "Development environment started"
    log_info "Application: http://localhost:5173"
    log_info "Logs: docker-compose logs -f online-time-dev"
}

cmd_test() {
    local coverage=false
    local watch=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --coverage) coverage=true; shift ;;
            --watch) watch=true; shift ;;
            *) log_error "Unknown test option: $1"; exit 1 ;;
        esac
    done
    
    log_header "Running Tests"
    
    local test_image="$(get_full_image_name "$DEFAULT_IMAGE_NAME" "test")"
    local test_command="npm run test:run"
    
    if [[ "$coverage" == "true" ]]; then
        test_command="npm run test:coverage"
    elif [[ "$watch" == "true" ]]; then
        test_command="npm run test:watch"
    fi
    
    # Build test image if needed
    if ! docker image inspect "$test_image" &>/dev/null; then
        log_info "Building test image..."
        docker build \
            --file docker/dev/Dockerfile \
            --target testing \
            --tag "$test_image" \
            "$BUILD_CONTEXT"
    fi
    
    # Run tests
    docker run --rm \
        --volume "$PROJECT_ROOT:/app" \
        --volume "/app/node_modules" \
        "$test_image" \
        $test_command
}

cmd_clean() {
    local clean_images=false
    local clean_containers=false
    local clean_volumes=false
    local clean_all=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --images) clean_images=true; shift ;;
            --containers) clean_containers=true; shift ;;
            --volumes) clean_volumes=true; shift ;;
            --all) clean_all=true; shift ;;
            *) log_error "Unknown clean option: $1"; exit 1 ;;
        esac
    done
    
    if [[ "$clean_all" == "true" ]]; then
        clean_images=true
        clean_containers=true
        clean_volumes=true
    fi
    
    log_header "Cleaning Docker Resources"
    
    if [[ "$clean_containers" == "true" ]]; then
        log_info "Removing containers..."
        docker-compose down --remove-orphans || true
        docker ps -aq --filter "label=app.name=online-time" | xargs -r docker rm -f || true
    fi
    
    if [[ "$clean_images" == "true" ]]; then
        log_info "Removing images..."
        docker images --filter "reference=online-time*" -q | xargs -r docker rmi -f || true
        docker images --filter "reference=$(get_image_name)*" -q | xargs -r docker rmi -f || true
    fi
    
    if [[ "$clean_volumes" == "true" ]]; then
        log_info "Removing volumes..."
        docker volume ls --filter "label=app.name=online-time" -q | xargs -r docker volume rm || true
    fi
    
    # Clean build cache
    log_info "Cleaning build cache..."
    docker builder prune -f || true
    
    log_success "Cleanup completed"
}

cmd_status() {
    log_header "Container Status"
    
    echo "Docker Compose Services:"
    docker-compose ps || true
    
    echo
    echo "Running Containers:"
    docker ps --filter "label=app.name=online-time" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    
    echo
    echo "Images:"
    docker images --filter "reference=online-time*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" || true
}

cmd_logs() {
    local service="${1:-online-time}"
    
    log_header "Container Logs: $service"
    
    if docker-compose ps "$service" &>/dev/null; then
        docker-compose logs -f "$service"
    else
        docker logs -f "online-time-$ENVIRONMENT" 2>/dev/null || \
        log_error "Container not found: $service"
    fi
}

cmd_health() {
    log_header "Health Check"
    
    local containers
    containers=$(docker ps --filter "label=app.name=online-time" --format "{{.Names}}" || true)
    
    if [[ -z "$containers" ]]; then
        log_warn "No running containers found"
        return 1
    fi
    
    for container in $containers; do
        log_info "Checking health of: $container"
        
        # Check container status
        local status
        status=$(docker inspect "$container" --format "{{.State.Status}}" 2>/dev/null || echo "not found")
        
        if [[ "$status" == "running" ]]; then
            # Try health check
            if docker exec "$container" curl -f http://localhost/health &>/dev/null; then
                log_success "$container is healthy"
            else
                log_warn "$container is running but health check failed"
            fi
        else
            log_error "$container status: $status"
        fi
    done
}

cmd_shell() {
    local service="${1:-online-time}"
    local container_name="online-time-$ENVIRONMENT"
    
    log_header "Opening Shell: $service"
    
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        docker exec -it "$container_name" /bin/bash
    else
        log_error "Container not running: $container_name"
        exit 1
    fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Parse global options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose) VERBOSE=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --tag) TAG="$2"; shift 2 ;;
            -h|--help) show_help; exit 0 ;;
            --*) log_error "Unknown global option: $1"; exit 1 ;;
            *) break ;;
        esac
    done
    
    # Get command
    local command="${1:-help}"
    shift || true
    
    # Validate Docker configuration
    if [[ "$command" != "help" ]]; then
        if ! validate_docker_config; then
            log_error "Docker configuration validation failed"
            exit 1
        fi
    fi
    
    # Execute command
    case $command in
        build) cmd_build "$@" ;;
        run) cmd_run "$@" ;;
        push) cmd_push "$@" ;;
        dev) cmd_dev "$@" ;;
        test) cmd_test "$@" ;;
        clean) cmd_clean "$@" ;;
        status) cmd_status "$@" ;;
        logs) cmd_logs "$@" ;;
        health) cmd_health "$@" ;;
        shell) cmd_shell "$@" ;;
        help) show_help ;;
        *) 
            log_error "Unknown command: $command"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Handle interruption
trap 'log_error "Script interrupted"; exit 130' INT TERM

# Run main function
main "$@"