#!/bin/bash

# ==============================================================================
# Quick Docker Build Script for Online-Time Project
# ==============================================================================
# 
# A simplified version of build-and-push.sh for quick local development builds.
# This script focuses on fast local builds without registry operations.
#
# Usage:
#   ./scripts/quick-build.sh [TAG]
#
# Examples:
#   ./scripts/quick-build.sh          # Build as online-time:latest
#   ./scripts/quick-build.sh dev      # Build as online-time:dev
#   ./scripts/quick-build.sh $(git rev-parse --short HEAD)  # Build with git hash
#
# ==============================================================================

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker-config.sh"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Configuration
IMAGE_NAME="${DEFAULT_IMAGE_NAME}"
TAG="${1:-latest}"
PLATFORM="${BUILD_PLATFORM:-linux/amd64}"  # Single platform for speed

main() {
    local start_time
    start_time=$(date +%s)
    
    echo
    log_info "Quick Docker Build - Online-Time Project"
    log_info "Building: ${IMAGE_NAME}:${TAG}"
    log_info "Platform: ${PLATFORM}"
    echo
    
    # Validate environment
    if ! validate_docker_config; then
        log_error "Environment validation failed"
        exit 1
    fi
    
    # Build image
    log_info "Starting build..."
    
    if docker build \
        --file "$DOCKERFILE_PATH" \
        --tag "${IMAGE_NAME}:${TAG}" \
        --platform "$PLATFORM" \
        --label "build.type=quick" \
        --label "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "$BUILD_CONTEXT"; then
        
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo
        log_success "Build completed in ${duration}s"
        log_info "Image: ${IMAGE_NAME}:${TAG}"
        
        # Show image size
        local size
        size=$(docker image inspect "${IMAGE_NAME}:${TAG}" --format '{{.Size}}' | numfmt --to=iec-i --suffix=B --format="%.1f")
        log_info "Size: ${size}"
        
        echo
        log_info "To run the image:"
        echo "  docker run -p 3000:80 ${IMAGE_NAME}:${TAG}"
        echo
    else
        log_error "Build failed"
        exit 1
    fi
}

# Run with error handling
trap 'log_error "Build interrupted"; exit 130' INT TERM
main "$@"