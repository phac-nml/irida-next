CREATE OR REPLACE TRIGGER "logidze_on_namespaces"
BEFORE UPDATE OR INSERT ON "namespaces" FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger(null, 'updated_at', '{created_at,metadata_summary,updated_at,attachments_updated_at}');
