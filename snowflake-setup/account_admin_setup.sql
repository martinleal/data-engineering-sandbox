USE ROLE ACCOUNTADMIN;

-- ============================================================
-- 1. CREATE CUSTOM ROLES
-- ============================================================

CREATE ROLE IF NOT EXISTS DATA_ARCHITECT;
CREATE ROLE IF NOT EXISTS DATA_ENGINEER;


-- ============================================================
-- 2. ROLE HIERARCHY
-- ============================================================

-- DATA_ARCHITECT inherits DATA_ENGINEER privileges.
-- This means an architect can also perform normal engineering work.

GRANT ROLE DATA_ENGINEER TO ROLE DATA_ARCHITECT;
GRANT ROLE DATA_ARCHITECT TO ROLE SYSADMIN;

-- ============================================================
-- 3. CREATE USER
-- ============================================================

CREATE USER IF NOT EXISTS DATA_ENGINEER_1
    PASSWORD = 'DUMMY'
    DEFAULT_ROLE = DATA_ENGINEER
    DEFAULT_WAREHOUSE = WH_DEV
    MUST_CHANGE_PASSWORD = FALSE;


-- Give the engineer role to the user

GRANT ROLE DATA_ENGINEER TO USER DATA_ENGINEER_1;
-- Vincula el nuevo rol a la jerarquía global (así SYSADMIN hereda sus permisos)




-- ============================================================
-- 4. CREATE WAREHOUSES
-- ============================================================

CREATE WAREHOUSE IF NOT EXISTS WH_PRO
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS WH_DEV
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS WH_ADMIN
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;


-- ============================================================
-- 5. GIVE DATA_ARCHITECT CONTROL OVER WAREHOUSES
-- ============================================================

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_PRO
TO ROLE DATA_ARCHITECT;

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_DEV
TO ROLE DATA_ARCHITECT;

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_ADMIN
TO ROLE DATA_ARCHITECT;


-- ============================================================
-- 6. GIVE DATA_ENGINEER COMPUTE ACCESS
-- ============================================================

GRANT USAGE
ON WAREHOUSE WH_DEV
TO ROLE DATA_ENGINEER;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE DATA_ARCHITECT;

