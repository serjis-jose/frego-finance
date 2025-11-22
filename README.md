# Frego Finance Microservice

Standalone Finance module for Frego ERP. This microservice handles all financial operations including AR (Accounts Receivable), AP (Accounts Payable), and General Ledger.

## Architecture

### Database Strategy
- **Database**: `frego_finance_db` (PostgreSQL)
- **Schema Strategy**: Schema-per-tenant (e.g., `finance_tenant_abc`, `finance_tenant_xyz`)
- **Isolation**: Each tenant has a dedicated schema with all finance tables

### External Dependencies
This module is loosely coupled with the main ERP system:
- **Party** (Customer/Vendor): Referenced by UUID only
- **Job** (Operations): Referenced by UUID only
- **Employee**: Referenced by UUID only
- **Branch**: Replicated locally for data integrity

No hard Foreign Key constraints exist to external databases, ensuring true microservice independence.

## Features

### Accounts Receivable (AR)
- Customer Invoices
- Receipt Management
- Credit Notes
- Advance Payments
- Invoice Allocation

### Accounts Payable (AP)
- Vendor Invoices
- Payment Processing
- Debit Notes
- Payment Against Invoice
- Direct Payments

### General Ledger (GL)
- Chart of Accounts
- Journal Entries
- GL Posting
- Trial Balance
- Financial Reports

## Getting Started

### Prerequisites
- Go 1.25.1 or higher
- PostgreSQL 14+
- Docker (optional)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd frego-finance
```

2. Install dependencies:
```bash
go mod download
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Generate code:
```bash
make generate
```

5. Run the service:
```bash
make run
```

## Database Provisioning

### Initial Setup

1. Create the finance database:
```sql
CREATE DATABASE frego_finance_db;
```

2. Run the provisioning script to create the stored procedure:
```bash
psql -d frego_finance_db -f db/provision_tenant.sql
```

### Provisioning a New Tenant

When a new tenant subscribes to the finance module:

```sql
CALL ensure_finance_tenant_schema(
  'tenant-uuid-here',  -- p_tenant_id
  'finance_acme'       -- p_schema (optional, defaults to finance_<uuid>)
);
```

This creates:
- Dedicated schema for the tenant
- All finance tables (AR, AP, GL)
- Lookup tables
- Triggers and functions

## API Integration

### Creating an Invoice

When an Operation Job is completed, the Operations Service should call:

```http
POST /finance/api/v1/invoices
Content-Type: application/json
X-Tenant-ID: tenant-uuid

{
  "customer_id": "uuid",
  "job_id": "uuid",
  "invoice_date": "2025-11-22",
  "currency_code": "AED",
  "lines": [...]
}
```

### Event-Driven Integration

The finance service can also consume events:
- `JobCompleted` → Create Invoice
- `CustomerCreated` → Cache customer info (optional)
- `PaymentReceived` → Record Receipt

## Development

### Code Generation

```bash
# Generate OpenAPI server code
make oapi

# Generate database code (sqlc)
make sqlc

# Generate all
make generate
```

### Running Tests

```bash
go test ./...
```

### Building

```bash
# Local build
go build -o bin/finance-server ./cmd/server

# Docker build
docker build -t frego-finance:latest .
```

## Deployment

### Docker

```bash
docker-compose up -d
```

### Kubernetes

```bash
kubectl apply -f k8s/
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_URL` | PostgreSQL connection string | - |
| `HTTP_ADDRESS` | HTTP server address | `:8080` |
| `KEYCLOAK_ISSUER` | Keycloak issuer URL | - |
| `KEYCLOAK_AUDIENCE` | Keycloak audience | - |
| `DEFAULT_TENANT` | Default tenant ID | - |
| `S3_BUCKET` | S3 bucket for documents | - |
| `S3_REGION` | S3 region | - |

## API Documentation

Once running, access the OpenAPI documentation at:
```
http://localhost:8080/finance/api/v1/docs
```

## Project Structure

```
frego-finance/
├── cmd/
│   └── server/          # Main application entry point
├── internal/
│   ├── api/             # OpenAPI generated code & handlers
│   ├── auth/            # Authentication middleware
│   ├── common/          # Shared utilities
│   ├── config/          # Configuration management
│   ├── db/              # Database layer
│   │   ├── sqlc/        # Generated SQLC code
│   │   └── queries/     # SQL queries
│   ├── dto/             # Data Transfer Objects
│   ├── logging/         # Logging utilities
│   ├── repository/      # Data access layer
│   ├── server/          # HTTP server setup
│   ├── service/         # Business logic
│   └── storage/         # File storage (S3)
├── db/
│   ├── schema.sql       # Static schema for tooling
│   ├── provision_tenant.sql  # Tenant provisioning
│   └── queries/         # SQL query files
├── api/
│   └── finance_openapi.yaml  # OpenAPI specification
├── docker/
│   └── docker-compose.yml
└── scripts/
    └── provision_tenant.sh
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linters
4. Submit a pull request

## License

Proprietary - Frego ERP
