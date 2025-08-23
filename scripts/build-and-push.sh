#!/bin/bash

# ==============================================================================
# Docker Multi-Platform Build and Push Script for Online-Time Project
# ==============================================================================
# 
# This script builds and pushes Docker images for multiple architectures using
# Docker Buildx. It supports various options for image naming, versioning,
# and deployment strategies.
#
# Usage:
#   ./scripts/build-and-push.sh [OPTIONS]
#
# Examples:
#   # Basic usage - builds and pushes with default settings
#   ./scripts/build-and-push.sh
#
#   # Specify custom image name and version
#   ./scripts/build-and-push.sh -i myuser/online-time -v 1.2.0
#
#   # Build only without pushing
#   ./scripts/build-and-push.sh --build-only
#
#   # Clean up build cache after build
#   ./scripts/build-and-push.sh --cleanup
#
#   # Use git commit hash as tag
#   ./scripts/build-and-push.sh --use-git-hash
#
# Requirements:
#   - Docker with buildx plugin
#   - Docker Hub account (logged in)
#   - Project must be built from project root directory
#
# ==============================================================================

set -euo pipefail

# =============================================================================
# Configuration and Default Values
# =============================================================================

# Default values
DEFAULT_IMAGE_NAME="online-time"
DEFAULT_VERSION="latest"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
DOCKERFILE_PATH="docker/base/Dockerfile"
BUILD_CONTEXT="."
BUILDX_BUILDER_NAME="online-time-builder"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script options
IMAGE_NAME=""
VERSION=""
PLATFORMS="$DEFAULT_PLATFORMS"
BUILD_ONLY=false
CLEANUP=false
USE_GIT_HASH=false
VERIFY_IMAGE=true
SCAN_IMAGE=false
VERBOSE=false
DRY_RUN=false

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $*"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $*"
    fi
}

show_help() {
    cat << EOF
Docker Multi-Platform Build and Push Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -i, --image IMAGE       Docker image name (default: $DEFAULT_IMAGE_NAME)
    -v, --version VERSION   Image version/tag (default: $DEFAULT_VERSION)
    -p, --platforms PLATFORMS
                           Target platforms (default: $DEFAULT_PLATFORMS)
    --build-only           Build image but don't push to registry
    --cleanup              Clean up build cache after operation
    --use-git-hash         Use git commit hash as version tag
    --no-verify            Skip image verification after build
    --scan                 Run security scan on built image (requires trivy)
    --verbose              Enable verbose logging
    --dry-run              Show what would be done without executing
    -h, --help             Show this help message

EXAMPLES:
    # Build and push with defaults
    $0

    # Custom image name and version
    $0 -i myuser/online-time -v 1.2.0

    # Build for specific platforms
    $0 -p "linux/amd64" --build-only

    # Use git commit as tag
    $0 --use-git-hash

    # Verbose mode with cleanup
    $0 --verbose --cleanup

REQUIREMENTS:
    - Docker with buildx support
    - Logged in to Docker registry
    - Run from project root directory

EOF
}

check_requirements() {
    log_step "Checking requirements..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        log_error "Docker buildx is not available"
        exit 1
    fi
    
    # Check if we're in the project root
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        log_error "Dockerfile not found at $DOCKERFILE_PATH. Are you in the project root?"
        exit 1
    fi
    
    if [[ ! -f "package.json" ]]; then
        log_error "package.json not found. Are you in the project root?"
        exit 1
    fi
    
    log_success "All requirements met"
}

get_git_info() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_HASH=$(git rev-parse --short HEAD)
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
        log_verbose "Git info - Hash: $GIT_HASH, Branch: $GIT_BRANCH, Tag: $GIT_TAG"
    else
        log_warn "Not in a git repository"
        GIT_HASH=""
        GIT_BRANCH=""
        GIT_TAG=""
    fi
}

setup_buildx() {
    log_step "Setting up Docker buildx..."
    
    # Create builder if it doesn't exist
    if ! docker buildx inspect "$BUILDX_BUILDER_NAME" &> /dev/null; then
        log_info "Creating buildx builder: $BUILDX_BUILDER_NAME"
        docker buildx create \
            --name "$BUILDX_BUILDER_NAME" \
            --driver docker-container \
            --bootstrap
    fi
    
    # Use the builder
    docker buildx use "$BUILDX_BUILDER_NAME"
    
    log_success "Buildx builder ready: $BUILDX_BUILDER_NAME"
}

determine_version() {
    if [[ "$USE_GIT_HASH" == "true" && -n "$GIT_HASH" ]]; then
        VERSION="$GIT_HASH"
        log_info "Using git hash as version: $VERSION"
    elif [[ -n "$GIT_TAG" ]]; then
        VERSION="$GIT_TAG"
        log_info "Using git tag as version: $VERSION"
    elif [[ -z "$VERSION" ]]; then
        VERSION="$DEFAULT_VERSION"
        log_info "Using default version: $VERSION"
    fi
}

build_image() {
    local full_image_name="$IMAGE_NAME:$VERSION"
    local build_args=()
    
    log_step "Building Docker image: $full_image_name"
    log_info "Platforms: $PLATFORMS"
    log_info "Dockerfile: $DOCKERFILE_PATH"
    log_info "Context: $BUILD_CONTEXT"
    
    # Prepare build arguments
    build_args+=(
        "--platform" "$PLATFORMS"
        "--file" "$DOCKERFILE_PATH"
        "--tag" "$full_image_name"
    )
    
    # Add latest tag if version is not latest
    if [[ "$VERSION" != "latest" ]]; then
        build_args+=("--tag" "$IMAGE_NAME:latest")
    fi
    
    # Add git metadata as labels
    if [[ -n "$GIT_HASH" ]]; then
        build_args+=("--label" "git.commit=$GIT_HASH")
        build_args+=("--label" "git.branch=$GIT_BRANCH")
    fi
    
    # Add build timestamp
    build_args+=("--label" "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)")
    
    # Add push flag if not build-only
    if [[ "$BUILD_ONLY" == "false" ]]; then
        build_args+=("--push")
    else
        build_args+=("--load")
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would execute: docker buildx build ${build_args[*]} $BUILD_CONTEXT"
        return 0
    fi
    
    # Execute build
    log_verbose "Executing: docker buildx build ${build_args[*]} $BUILD_CONTEXT"
    
    if docker buildx build "${build_args[@]}" "$BUILD_CONTEXT"; then
        log_success "Image built successfully: $full_image_name"
        return 0
    else
        log_error "Failed to build image"
        return 1
    fi
}

verify_image() {
    if [[ "$VERIFY_IMAGE" == "false" || "$BUILD_ONLY" == "false" ]]; then
        return 0
    fi
    
    local full_image_name="$IMAGE_NAME:$VERSION"
    
    log_step "Verifying built image..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would verify image: $full_image_name"
        return 0
    fi
    
    # Check if image exists
    if docker image inspect "$full_image_name" &> /dev/null; then
        log_success "Image verification passed: $full_image_name"
        
        # Show image info
        log_info "Image details:"
        docker image inspect "$full_image_name" --format "  Size: {{.Size}} bytes"
        docker image inspect "$full_image_name" --format "  Created: {{.Created}}"
        docker image inspect "$full_image_name" --format "  Architecture: {{.Architecture}}"
    else
        log_error "Image verification failed: $full_image_name not found"
        return 1
    fi
}

scan_image() {
    if [[ "$SCAN_IMAGE" == "false" ]]; then
        return 0
    fi
    
    local full_image_name="$IMAGE_NAME:$VERSION"
    
    log_step "Scanning image for vulnerabilities..."
    
    if ! command -v trivy &> /dev/null; then
        log_warn "Trivy not found, skipping security scan"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would scan image: $full_image_name"
        return 0
    fi
    
    if trivy image "$full_image_name"; then
        log_success "Security scan completed"
    else
        log_warn "Security scan found issues (this won't stop the build)"
    fi
}

cleanup_builder() {
    if [[ "$CLEANUP" == "false" ]]; then
        return 0
    fi
    
    log_step "Cleaning up build cache..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would clean up build cache"
        return 0
    fi
    
    # Prune buildx cache
    docker buildx prune --force
    
    log_success "Build cache cleaned up"
}

show_summary() {
    echo
    log_success "Build Summary"
    echo "=================================="
    echo "  Image Name: $IMAGE_NAME"
    echo "  Version: $VERSION"
    echo "  Platforms: $PLATFORMS"
    echo "  Build Only: $BUILD_ONLY"
    echo "  Dockerfile: $DOCKERFILE_PATH"
    
    if [[ -n "$GIT_HASH" ]]; then
        echo "  Git Hash: $GIT_HASH"
        echo "  Git Branch: $GIT_BRANCH"
    fi
    
    if [[ "$BUILD_ONLY" == "false" && "$DRY_RUN" == "false" ]]; then
        echo
        log_info "Image pushed to registry:"
        echo "  docker pull $IMAGE_NAME:$VERSION"
        if [[ "$VERSION" != "latest" ]]; then
            echo "  docker pull $IMAGE_NAME:latest"
        fi
    fi
    echo
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local start_time
    start_time=$(date +%s)
    
    echo
    log_info "Starting Docker multi-platform build process..."
    log_info "Project: Online-Time"
    echo
    
    # Check requirements
    check_requirements
    
    # Get git information
    get_git_info
    
    # Determine final image name and version
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="$DEFAULT_IMAGE_NAME"
    determine_version
    
    # Setup buildx
    setup_buildx
    
    # Build image
    if ! build_image; then
        log_error "Build failed"
        exit 1
    fi
    
    # Verify image
    verify_image
    
    # Security scan
    scan_image
    
    # Cleanup
    cleanup_builder
    
    # Show summary
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    show_summary
    log_success "Build completed successfully in ${duration}s"
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -p|--platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --cleanup)
                CLEANUP=true
                shift
                ;;
            --use-git-hash)
                USE_GIT_HASH=true
                shift
                ;;
            --no-verify)
                VERIFY_IMAGE=false
                shift
                ;;
            --scan)
                SCAN_IMAGE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Handle script interruption
trap 'log_error "Script interrupted"; exit 130' INT TERM

# Parse command line arguments
parse_args "$@"

# Execute main function
main

log_success "Script completed successfully!"