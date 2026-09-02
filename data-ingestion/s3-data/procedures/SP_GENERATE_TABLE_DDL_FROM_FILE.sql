CREATE OR REPLACE PROCEDURE BRONZE.AUTOMATION.SP_GENERATE_TABLE_DDL_FROM_FILE(
    stage_location STRING, 
    file_format_name STRING, 
    target_table_name STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'generate_ddl'
AS
$$
def generate_ddl(session, stage_location, file_format_name, target_table_name):
    try:
        # 1. Ask Snowflake to infer the schema from the file
        infer_sql = f"""
            SELECT COLUMN_NAME, 'VARCHAR' AS TYPE, NULLABLE 
            FROM TABLE(
                INFER_SCHEMA(
                    LOCATION => '{stage_location}',
                    FILE_FORMAT => '{file_format_name}'
                )
            )
            ORDER BY ORDER_ID;
        """
        
        columns_df = session.sql(infer_sql).collect()
        
        if not columns_df:
            return "ERROR: No columns inferred. Check if the file exists and the format is correct."
        
        # 2. Build the column definitions
        col_definitions = []
        for row in columns_df:
            # Clean up column names and enclose in quotes to prevent reserved keyword errors
            col_name = row['COLUMN_NAME']
            col_type = row['TYPE']
            nullable = "" if row['NULLABLE'] else " NOT NULL"
            
            col_definitions.append(f'    "{col_name}" {col_type}{nullable}')
            
        # 3. Append your standard architecture metadata columns
        col_definitions.append('    "_RECORD_SOURCE" VARCHAR')
        col_definitions.append('    "_LOAD_TIMESTAMP" TIMESTAMP_LTZ')
        col_definitions.append('    "_LOAD_ROLE" VARCHAR')
        
        # 4. Construct the final DDL statement
        columns_str = ",\n".join(col_definitions)
        ddl_sql = f"CREATE TABLE IF NOT EXISTS {target_table_name} (\n{columns_str}\n);"
        ddl_sql = ddl_sql.upper().replace('"', '')
        return f"-- SUCCESS. Table DDL created:\n{ddl_sql}"
        
    except Exception as e:
        return f"ERROR generating DDL: {str(e)}"
$$;
