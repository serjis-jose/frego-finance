#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GO_BIN=${GO:-go}
MAKE_BIN=${MAKE:-make}
OUTPUT_DIR=${OUTPUT_DIR:-"$ROOT_DIR/bin"}
BINARY_NAME=${BINARY_NAME:-finance-server}
SKIP_GENERATE=${SKIP_GENERATE:-0}
GOCACHE_DIR=${GOCACHE:-"$ROOT_DIR/.cache/go-build"}
SQLC_VERSION=${SQLC_VERSION:-v1.30.0}
OAPI_VERSION=${OAPI_VERSION:-v2.5.0}

GOPATH_BIN=$("$GO_BIN" env GOPATH)/bin
export PATH="$GOPATH_BIN:$PATH"

mkdir -p "$OUTPUT_DIR" "$GOCACHE_DIR"
export GOCACHE="$GOCACHE_DIR"

# Ensure codegen tools are present at the expected versions (avoids config parse errors)
CURRENT_SQLC_VER=$(sqlc -version 2>/dev/null | awk 'NR==1{print $2}' || true)
if [[ -z "$CURRENT_SQLC_VER" || "$CURRENT_SQLC_VER" != "${SQLC_VERSION#v}" ]]; then
	( cd / && "$GO_BIN" install "github.com/sqlc-dev/sqlc/cmd/sqlc@${SQLC_VERSION}" )
fi
CURRENT_OAPI_VER=$(oapi-codegen -version 2>/dev/null | awk 'NR==2{print $1}' || true)
if [[ -z "$CURRENT_OAPI_VER" || "$CURRENT_OAPI_VER" != "${OAPI_VERSION#v}" ]]; then
	( cd / && "$GO_BIN" install "github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@${OAPI_VERSION}" )
fi

if [[ "$SKIP_GENERATE" != "1" ]]; then
	echo "==> running code generation"
	(cd "$ROOT_DIR" && "$MAKE_BIN" generate)
fi

if [[ ! -f "$ROOT_DIR/go.sum" ]]; then
	echo "==> generating go.sum"
	(cd "$ROOT_DIR" && "$GO_BIN" mod tidy)
fi

echo "==> building $BINARY_NAME"
(cd "$ROOT_DIR" && "$GO_BIN" build -o "$OUTPUT_DIR/$BINARY_NAME" ./cmd/server)

echo "==> build complete: $OUTPUT_DIR/$BINARY_NAME"
