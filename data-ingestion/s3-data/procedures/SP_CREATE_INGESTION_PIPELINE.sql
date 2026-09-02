CREATE OR REPLACE PROCEDURE BRONZE.AUTOMATION.SP_CREATE_INGESTION_PIPELINE(stage_name STRING, file_name STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python', 'pyyaml')
HANDLER = 'create_ingestion_pipeline'
AS
$$
from snowflake.snowpark.files import SnowflakeFile
import yaml

def create_ingestion_pipeline(session, stage_name, file_name):
    try:
        # Format the strings to ensure there is exactly one slash between them
        stage_name = stage_name.rstrip('/')
        file_name = file_name.lstrip('/')
        
        # Add the @ symbol to the stage if the user forgot it
        if not stage_name.startswith('@'):
            stage_name = f"@{stage_name}"
            
        full_file_path = f"{stage_name}/{file_name}"

        # 1. Read and parse the YAML configuration using the raw string path
        # require_scoped_url=False is required when passing a string instead of BUILD_SCOPED_FILE_URL
        with SnowflakeFile.open(full_file_path, 'r', require_scoped_url=False) as f:
            config = yaml.safe_load(f)

        # Extract variables safely
        pipeline_name = config['pipeline']['name']
        
        # Source & Target
        source_stage = config['source']['stage_name']
        file_path = config['source'].get('file_path', '')
        
        target_db = config['target']['database']
        target_schema = config['target']['schema']
        target_table = config['target']['table']
        fq_target_table = f"{target_db}.{target_schema}.{target_table}"
        
        # Copy Into
        ci_config = config.get('copy_into', {})
        on_error = ci_config.get('on_error')
        ff_config = ci_config.get('file_format', {})
        ff_name = ff_config.get('file_format_name')
        ff_type = ff_config.get('type')
        skip_header = ff_config.get('skip_header', 0)
        error_on_column_count_mismatch = ff_config.get('error_on_column_count_mismatch')
        error_on_column_count_mismatch_sql = 'TRUE' if error_on_column_count_mismatch else 'FALSE'

        if ff_name:
            ff_sql = f"(FORMAT_NAME = ' || CHR(39) || '{ff_name}' || CHR(39) || ')"
        else:
            # If using an inline format: FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 ...)
            ff_sql = f"""(
                    TYPE = ' || CHR(39) || '{ff_type}' || CHR(39) || ' 
                    SKIP_HEADER = {skip_header}
                    ERROR_ON_COLUMN_COUNT_MISMATCH = {error_on_column_count_mismatch_sql}
                )"""

        # Build the Generated Procedure (Snowflake Scripting)
        proc_name = f"{target_db}.{target_schema}.SP_{pipeline_name}"

        # Build the SELECT-based COPY INTO statement
        select_list = []
        
        if ff_type in ['JSON', 'PARQUET', 'AVRO', 'ORC']:
            # For semi-structured, the entire payload is in $1
            select_list.append("$1")
        else:
            # For CSV/TSV, dynamically map $1, $2, $3... based on table schema
            target_table_obj = session.table(fq_target_table)
            all_columns = [field.name.upper() for field in target_table_obj.schema.fields]
            
            metadata_cols = ['_RECORD_SOURCE', '_LOAD_TIMESTAMP', '_LOAD_ROLE']
            data_columns = [col for col in all_columns if col not in metadata_cols]
            
            select_list = [f"${i+1}" for i in range(len(data_columns))]

        select_list.append("METADATA$FILENAME")
        select_list.append("CURRENT_TIMESTAMP()")
        select_list.append("CURRENT_ROLE()")
        
        select_clause = ", ".join(select_list)

        proc_delimiter = '$'+'$'
        create_proc_sql = f"""
        CREATE OR REPLACE PROCEDURE {proc_name}(P_FILE_PATH STRING, P_PATTERN STRING)
        RETURNS STRING
        LANGUAGE SQL
        EXECUTE AS CALLER
        AS
        {proc_delimiter}
        DECLARE
            v_copy_sql STRING;
            error_msg STRING;
        BEGIN
            SYSTEM$LOG('INFO', 'START: Pipeline {pipeline_name} execution started for path ' || :P_FILE_PATH || ' and pattern ' || :P_PATTERN);
            
            v_copy_sql := 'COPY INTO {fq_target_table}
                FROM (
                    SELECT 
                        {select_clause}
                    FROM {source_stage}' || :P_FILE_PATH || '
                )
                FILE_FORMAT = {ff_sql}
                ON_ERROR = ' || CHR(39) || '{on_error}' || CHR(39) || '
                PATTERN = ' || CHR(39) || :P_PATTERN || CHR(39);
            
            EXECUTE IMMEDIATE :v_copy_sql;
            
            SYSTEM$LOG('INFO', 'SUCCESS: Pipeline {pipeline_name} executed successfully.');
            RETURN \'SUCCESS: {pipeline_name} executed.\';
            
        EXCEPTION
            WHEN OTHER THEN
                error_msg := SQLCODE || ': ' || SQLERRM;
                SYSTEM$LOG('ERROR', 'FAILED: Pipeline {pipeline_name}. Error: ' || :error_msg);
                RAISE;
        END;
        {proc_delimiter};
        """

        # 5. Execute the generation
        session.sql(create_proc_sql).collect()
        
        return f"SUCCESS: Generated procedure {proc_name}."
        
    except Exception as e:
        return f"ERROR generating pipeline: {str(e)}"
$$;