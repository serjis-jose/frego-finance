# syntax=docker/dockerfile:1

FROM golang:1.25.1 AS builder
WORKDIR /app

ARG SQLC_VERSION=v1.30.0
ARG OAPI_CODEGEN_VERSION=v2.5.0

RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@${SQLC_VERSION} \
    && go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@${OAPI_CODEGEN_VERSION}

COPY . .

RUN oapi-codegen --config api/oapi-codegen.yaml api/finance_openapi.yaml \
    && sqlc generate \
    && cp api/finance_openapi.yaml internal/server/openapi.yaml

RUN go mod tidy 

ENV CGO_ENABLED=0
ARG TARGETARCH
RUN GOOS=linux GOARCH=${TARGETARCH:-amd64} go build -o /app/bin/finance-server ./cmd/server

FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app

COPY --from=builder /app/bin/finance-server /usr/local/bin/finance-server
COPY --from=builder /app/db /app/db

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/finance-server"]
