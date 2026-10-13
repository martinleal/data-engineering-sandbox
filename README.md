# Project Structure

This repository contains a data engineering POC built around Snowflake, dbt, and a medallion-inspired Data Vault architecture.

- **`data-ingestion/`** — In-progress ingestion framework containing two Snowflake stored procedures and eight YAML files defining source file metadata. The goal is to standardize and automate the ingestion of source data into Snowflake.
- **`snowflake-setup/`** — Two SQL scripts to provision the POC environment, including roles, databases, and tables, with an emphasis on separating responsibilities and environments.
- **`data-transformation/`** — The dbt project responsible for transforming data through five layers:
  - **Raw:** Source data ingested into Snowflake.
  - **Staging:** Standardized source data, including derived columns and hash keys.
  - **Raw Data Vault (RDV):** Hubs, links, and satellites that capture business keys, relationships, and source history.
  - **Business Data Vault (BDV):** Business-oriented rules, derived structures, and enriched data.
  - **Gold:** Analytics-ready dimensions and fact tables for reporting and downstream consumption.

The project is under active development. Some ingestion components and transformations are still in progress.