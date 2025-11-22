#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GO_BIN=${GO_BIN:-go}

echo "==> Compiling Finance microservice"

cd "$ROOT_DIR"

# Clean previous builds
echo "    Cleaning previous builds..."
rm -rf bin/
mkdir -p bin/

# Build for current platform
echo "    Building for current platform..."
CGO_ENABLED=0 ${GO_BIN} build -o bin/finance-server ./cmd/server

echo "    Build complete: bin/finance-server"

# Optionally build for multiple platforms
if [ "${BUILD_ALL_PLATFORMS:-false}" = "true" ]; then
	echo "    Building for multiple platforms..."
	
	# Linux AMD64
	echo "    - linux/amd64"
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 ${GO_BIN} build -o bin/finance-server-linux-amd64 ./cmd/server
	
	# Linux ARM64
	echo "    - linux/arm64"
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 ${GO_BIN} build -o bin/finance-server-linux-arm64 ./cmd/server
	
	# macOS AMD64
	echo "    - darwin/amd64"
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 ${GO_BIN} build -o bin/finance-server-darwin-amd64 ./cmd/server
	
	# macOS ARM64
	echo "    - darwin/arm64"
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 ${GO_BIN} build -o bin/finance-server-darwin-arm64 ./cmd/server
	
	echo "    All platform builds complete"
fi

echo "==> Done!"
