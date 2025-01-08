CREATE TRIGGER "logidze_on_workflow_executions"
BEFORE UPDATE OR INSERT ON "workflow_executions" FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger(null, 'updated_at', '{created_at,updated_at,cleaned,http_error_code,metadata,workflow_params,workflow_type,workflow_type_version,workflow_engine,workflow_engine_version,workflow_engine_parameters,workflow_url,namespace_id,tags,blob_run_directory,id,submitter_id,email_notification,update_samples,cleaned,attachments_updated_at}');
