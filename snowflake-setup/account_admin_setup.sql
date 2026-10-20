
USE ROLE ACCOUNTADMIN;

-- ============================================================
-- 1. CREATE CUSTOM ROLES
-- ============================================================

CREATE ROLE IF NOT EXISTS DATA_ARCHITECT;
CREATE ROLE IF NOT EXISTS DATA_ENGINEER;
CREATE ROLE IF NOT EXISTS DATA_CI;


-- ============================================================
-- 2. ROLE HIERARCHY
-- ============================================================

-- Architect inherits engineering and CI privileges.
-- SYSADMIN inherits the architect role.

GRANT ROLE DATA_ENGINEER TO ROLE DATA_ARCHITECT;
GRANT ROLE DATA_CI TO ROLE DATA_ARCHITECT;
GRANT ROLE DATA_ARCHITECT TO ROLE SYSADMIN;


-- ============================================================
-- 3. CREATE USERS
-- ============================================================


CREATE USER IF NOT EXISTS DATA_ENGINEER_1
    PASSWORD = 'DUMMY'
    DEFAULT_ROLE = DATA_ENGINEER
    DEFAULT_WAREHOUSE = WH_DEV
    MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE DATA_ENGINEER TO USER DATA_ENGINEER_1;



CREATE USER IF NOT EXISTS DATA_CI_GITHUB
    TYPE = SERVICE
    DEFAULT_ROLE = DATA_CI
    DEFAULT_WAREHOUSE = WH_CI;

GRANT ROLE DATA_CI TO USER DATA_CI_GITHUB; 

-- To create private and public keys in local environment:
-- openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
-- openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
ALTER USER DATA_CI_GITHUB
SET RSA_PUBLIC_KEY = '<paste_public_key_here>';


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

CREATE WAREHOUSE IF NOT EXISTS WH_CI
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
-- 5. ARCHITECT: WAREHOUSE CONTROL
-- ============================================================

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_PRO TO ROLE DATA_ARCHITECT;

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_DEV TO ROLE DATA_ARCHITECT;

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_CI TO ROLE DATA_ARCHITECT;

GRANT USAGE, OPERATE, MODIFY
ON WAREHOUSE WH_ADMIN TO ROLE DATA_ARCHITECT;


-- ============================================================
-- 6. ENGINEER: DEVELOPMENT COMPUTE
-- ============================================================

GRANT USAGE
ON WAREHOUSE WH_DEV TO ROLE DATA_ENGINEER;


-- ============================================================
-- 7. CI: DEDICATED COMPUTE
-- ============================================================

GRANT USAGE
ON WAREHOUSE WH_CI TO ROLE DATA_CI;


-- ============================================================
-- 8. DATABASE CREATION
-- ============================================================

GRANT CREATE DATABASE
ON ACCOUNT TO ROLE DATA_ARCHITECT;
