CREATE OR REPLACE TRIGGER "logidze_on_personal_access_tokens"
BEFORE UPDATE OR INSERT ON "personal_access_tokens" FOR EACH ROW
WHEN (coalesce(current_setting('logidze.disabled', true), '') <> 'on')
-- Parameters: history_size_limit (integer), timestamp_column (text), filtered_columns (text[]),
-- include_columns (boolean), debounce_time_ms (integer)
EXECUTE PROCEDURE logidze_logger(null, 'updated_at', '{last_used_at}');
