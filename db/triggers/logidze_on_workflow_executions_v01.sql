CREATE TRIGGER "logidze_on_workflow_executions"
BEFORE UPDATE OR INSERT ON "workflow_executions" FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger(null, 'updated_at', '{run_id,name,state,deleted_at}', true);
