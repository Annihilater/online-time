#!/bin/bash

# ==============================================================================
# Docker Configuration for Online-Time Project
# ==============================================================================
# 
# This file contains shared configuration for Docker operations.
# Source this file in other scripts to use consistent settings.
#
# Usage:
#   source scripts/docker-config.sh
#
# ==============================================================================

# Docker Registry Configuration
export DOCKER_REGISTRY="docker.io"
export DOCKER_USERNAME="${DOCKER_USERNAME:-}"
export DEFAULT_IMAGE_NAME="online-time"
export DEFAULT_REGISTRY_NAME="${DOCKER_USERNAME}/${DEFAULT_IMAGE_NAME}"

# Build Configuration
export DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
export DOCKERFILE_PATH="docker/base/Dockerfile"
export BUILD_CONTEXT="."

# Build Arguments
export BUILD_NODE_VERSION="18"
export BUILD_NGINX_VERSION="alpine"

# Image Labels
export IMAGE_TITLE="Online Time - Multi-functional Time Tools"
export IMAGE_DESCRIPTION="A comprehensive web application with alarm, timer, stopwatch, and world clock features"
export IMAGE_VENDOR="Online-Time Project"
export IMAGE_URL="https://github.com/yourname/online-time"
export IMAGE_DOCUMENTATION="https://github.com/yourname/online-time/README.md"

# Buildx Configuration
export BUILDX_BUILDER_NAME="online-time-builder"
export BUILDX_DRIVER="docker-container"

# Security and Quality
export ENABLE_SECURITY_SCAN="${ENABLE_SECURITY_SCAN:-false}"
export ENABLE_IMAGE_SIGN="${ENABLE_IMAGE_SIGN:-false}"
export SCAN_SEVERITY="${SCAN_SEVERITY:-HIGH,CRITICAL}"

# Performance Settings
export BUILD_CACHE_TYPE="registry"
export BUILD_CACHE_MODE="max"
export PARALLEL_BUILDS="${PARALLEL_BUILDS:-true}"

# Development vs Production
export BUILD_MODE="${BUILD_MODE:-production}"
export ENABLE_DEBUG="${ENABLE_DEBUG:-false}"

# Common functions
get_image_name() {
    local name="${1:-$DEFAULT_IMAGE_NAME}"
    if [[ -n "$DOCKER_USERNAME" ]]; then
        echo "${DOCKER_USERNAME}/${name}"
    else
        echo "${name}"
    fi
}

get_full_image_name() {
    local name="${1:-$DEFAULT_IMAGE_NAME}"
    local tag="${2:-latest}"
    echo "$(get_image_name "$name"):${tag}"
}

validate_docker_config() {
    local errors=0
    
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        echo "ERROR: Dockerfile not found at $DOCKERFILE_PATH" >&2
        ((errors++))
    fi
    
    if [[ ! -f "package.json" ]]; then
        echo "ERROR: package.json not found in current directory" >&2
        ((errors++))
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker not found in PATH" >&2
        ((errors++))
    fi
    
    if ! docker buildx version &> /dev/null; then
        echo "ERROR: Docker buildx not available" >&2
        ((errors++))
    fi
    
    return $errors
}

print_docker_config() {
    echo "Docker Configuration:"
    echo "===================="
    echo "Registry: $DOCKER_REGISTRY"
    echo "Username: ${DOCKER_USERNAME:-'(not set)'}"
    echo "Default Image: $(get_image_name)"
    echo "Platforms: $DEFAULT_PLATFORMS"
    echo "Dockerfile: $DOCKERFILE_PATH"
    echo "Build Context: $BUILD_CONTEXT"
    echo "Builder: $BUILDX_BUILDER_NAME"
    echo "Security Scan: $ENABLE_SECURITY_SCAN"
    echo "Build Mode: $BUILD_MODE"
    echo
}