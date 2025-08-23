# ==============================================================================
# Development Dockerfile for Online-Time Project
# ==============================================================================
# 
# This Dockerfile is optimized for development with hot reload capabilities.
# It supports multiple stages for different development needs.
#
# Usage:
#   # Development with hot reload
#   docker build --target development -t online-time:dev .
#
#   # Development with debugging
#   docker build --target debug -t online-time:debug .
#
# ==============================================================================

FROM node:18-alpine AS base

# Install additional development tools
RUN apk add --no-cache \
    git \
    curl \
    bash \
    vim \
    less

# Create app user
RUN addgroup -g 1001 -S appuser && \
    adduser -S -D -H -u 1001 -s /bin/bash -G appuser appuser

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci --silent && \
    npm cache clean --force

# Create node_modules volume mount point and set permissions
RUN mkdir -p node_modules && \
    chown -R appuser:appuser /app

# Development stage
FROM base AS development

# Set development environment
ENV NODE_ENV=development
ENV VITE_HMR_HOST=0.0.0.0

# Copy source code
COPY --chown=appuser:appuser . .

# Switch to app user
USER appuser

# Expose Vite dev server port
EXPOSE 5173

# Health check for development
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5173 || exit 1

# Default command for development
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

# Debug stage with additional tools
FROM development AS debug

# Switch back to root for tool installation
USER root

# Install debugging tools
RUN npm install -g \
    nodemon \
    @types/node \
    typescript \
    ts-node

# Install system debugging tools
RUN apk add --no-cache \
    strace \
    htop \
    net-tools

# Switch back to app user
USER appuser

# Set debug environment
ENV DEBUG=*
ENV NODE_OPTIONS="--inspect=0.0.0.0:9229"

# Expose debug port
EXPOSE 9229

# Debug command
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--debug"]

# Testing stage
FROM base AS testing

# Copy source code
COPY --chown=appuser:appuser . .

# Switch to app user
USER appuser

# Set test environment
ENV NODE_ENV=test
ENV CI=true

# Run tests by default
CMD ["npm", "run", "test:run"]

# Build stage for development builds
FROM base AS build-dev

# Copy source code
COPY --chown=appuser:appuser . .

# Switch to app user
USER appuser

# Build the application
RUN npm run build

# Development nginx stage
FROM nginx:alpine AS nginx-dev

# Install curl for health checks
RUN apk add --no-cache curl

# Copy nginx configuration
COPY docker/base/nginx.conf /etc/nginx/nginx.conf

# Copy built application
COPY --from=build-dev /app/dist /usr/share/nginx/html

# Create nginx user and set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]