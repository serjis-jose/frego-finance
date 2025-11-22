# 🗄️ SQL Migration Guide - Shared Tenant Registry

## Quick Start (3 Easy Steps)

### **Step 1: Create the Database**
```bash
createdb frego_tenant_db
```

### **Step 2: Run the Migration SQL**
```bash
psql frego_tenant_db -f db/migration_to_shared_tenant_registry.sql
```

### **Step 3: Verify**
```bash
psql frego_tenant_db -c "SELECT * FROM tenant_registry;"
```

**That's it! ✅**

---

## Alternative: Copy-Paste Method

If you prefer, just open `psql` and paste:

### **1. Connect to PostgreSQL**
```bash
psql -U postgres
```

### **2. Create Database**
```sql
CREATE DATABASE frego_tenant_db;
\c frego_tenant_db
```

### **3. Copy & Paste the SQL**
Open `db/migration_to_shared_tenant_registry.sql` and copy all contents, then paste into psql.

---

## Manual Step-by-Step (if you want control)

### **Step 1: Create Database**
```bash
psql -U postgres <<SQL
CREATE DATABASE frego_tenant_db;
SQL
```

### **Step 2: Create Tables**
```bash
psql frego_tenant_db <<SQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE tenant_registry (
  tenant_id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_slug          text UNIQUE NOT NULL,
  tenant_name          text NOT NULL,
  contact_email        text,
  is_active            boolean DEFAULT true,
  modules_subscribed   text[] DEFAULT '{}',
  operations_schema    text,
  finance_schema       text,
  inventory_schema     text,
  hrms_schema          text,
  created_at           timestamptz DEFAULT now(),
  created_by           text,
  modified_at          timestamptz,
  modified_by          text
);

CREATE TABLE tenant_module_log (
  id                uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id         uuid NOT NULL REFERENCES tenant_registry(tenant_id),
  module_name       text NOT NULL,
  action            text NOT NULL,
  schema_name       text,
  status            text NOT NULL,
  error_message     text,
  provisioned_at    timestamptz DEFAULT now(),
  provisioned_by    text
);
SQL
```

### **Step 3: Verify**
```bash
psql frego_tenant_db -c "\dt"
psql frego_tenant_db -c "SELECT * FROM tenant_registry;"
```

---

## One-Liner (Easiest!)

```bash
createdb frego_tenant_db && psql frego_tenant_db -f db/migration_to_shared_tenant_registry.sql
```

---

## Using Docker

If PostgreSQL is in Docker:

```bash
# Copy SQL file into container
docker cp db/migration_to_shared_tenant_registry.sql frego-finance-db:/tmp/

# Create database and run migration
docker exec -it frego-finance-db bash -c "
  createdb -U postgres frego_tenant_db &&
  psql -U postgres frego_tenant_db -f /tmp/migration_to_shared_tenant_registry.sql
"
```

---

## Verification Commands

### Check database exists
```bash
psql -U postgres -l | grep frego_tenant_db
```

### Check tables were created
```bash
psql frego_tenant_db -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
"
```

### Check functions/procedures
```bash
psql frego_tenant_db -c "
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public';
"
```

### Test a function
```bash
psql frego_tenant_db -c "
SELECT tenant_has_module('550e8400-e29b-41d4-a716-446655440000'::uuid, 'finance');
"
```

---

## What Gets Created

✅ `tenant_registry` table
✅ `tenant_module_log` table  
✅ `tenant_has_module()` function
✅ `get_tenant_schema()` function
✅ `register_tenant()` procedure
✅ `subscribe_tenant_to_module()` procedure
✅ `mark_module_provisioned()` procedure
✅ All indexes

---

## Rollback

If you need to start over:

```bash
# Drop and recreate
dropdb frego_tenant_db
createdb frego_tenant_db
psql frego_tenant_db -f db/migration_to_shared_tenant_registry.sql
```

---

## Next Steps After Migration

1. **Install provisioning procedure in finance DB**
   ```bash
   psql frego_finance_db -f db/provision_tenant.sql
   ```

2. **Provision a test tenant**
   ```bash
   psql frego_tenant_db <<SQL
   CALL register_tenant(
     '550e8400-e29b-41d4-a716-446655440000'::uuid,
     'demo',
     'Demo Company',
     'demo@example.com'
   );
   
   CALL subscribe_tenant_to_module(
     '550e8400-e29b-41d4-a716-446655440000'::uuid,
     'finance',
     'finance_demo'
   );
   SQL
   
   psql frego_finance_db <<SQL
   CALL ensure_finance_tenant_schema(
     '550e8400-e29b-41d4-a716-446655440000'::uuid,
     'finance_demo'
   );
   SQL
   ```

3. **Update .env files**
   ```bash
   TENANT_DB_URL=postgres://postgres:postgres@localhost:5432/frego_tenant_db
   ```

---

**Pick whichever method is easiest for you!** 🚀
