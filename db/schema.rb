# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_04_23_155817) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.datetime "created_at", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["created_at"], name: "index_active_storage_attachments_on_created_at"
    t.index ["record_id"], name: "index_active_storage_attachments_on_record_id"
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_active_storage_blobs_on_created_at"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "variation_digest", null: false
    t.uuid "blob_id", null: false
    t.index ["blob_id"], name: "index_active_storage_variant_records_on_blob_id"
  end

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "metadata", default: {}, null: false
    t.datetime "deleted_at"
    t.string "attachable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.uuid "attachable_id", null: false
    t.string "puid", null: false
    t.index ["attachable_id"], name: "index_attachments_on_attachable_id"
    t.index ["created_at"], name: "index_attachments_on_created_at"
    t.index ["metadata"], name: "index_attachments_on_metadata", using: :gin
    t.index ["puid"], name: "index_attachments_on_puid"
  end

  create_table "data_exports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "export_type", null: false
    t.string "status", null: false
    t.jsonb "export_parameters", default: {}, null: false
    t.datetime "expires_at"
    t.boolean "email_notification", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.uuid "user_id", null: false
    t.jsonb "manifest", default: {}, null: false
    t.index ["created_at"], name: "index_data_exports_on_created_at"
    t.index ["user_id"], name: "index_data_exports_on_user_id"
  end

  create_table "members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "access_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.datetime "deleted_at"
    t.date "expires_at"
    t.uuid "user_id", null: false
    t.uuid "namespace_id", null: false
    t.uuid "created_by_id", null: false
    t.index ["created_at"], name: "index_members_on_created_at"
    t.index ["created_by_id"], name: "index_members_on_created_by_id"
    t.index ["deleted_at"], name: "index_members_on_deleted_at"
    t.index ["expires_at"], name: "index_members_on_expires_at"
    t.index ["namespace_id"], name: "index_members_on_namespace_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "namespace_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "namespace_id", null: false
    t.datetime "deleted_at"
    t.jsonb "log_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_namespace_bots_on_deleted_at"
    t.index ["user_id", "namespace_id"], name: "index_bot_user_with_namespace", unique: true
  end

  create_table "namespace_group_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "expires_at"
    t.integer "group_access_level", null: false
    t.string "namespace_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.jsonb "log_data"
    t.uuid "group_id", null: false
    t.uuid "namespace_id", null: false
    t.index ["created_at"], name: "index_namespace_group_links_on_created_at"
    t.index ["deleted_at"], name: "index_namespace_group_links_on_deleted_at"
    t.index ["group_id"], name: "index_namespace_group_links_on_group_id"
    t.index ["namespace_id"], name: "index_namespace_group_links_on_namespace_id"
  end

  create_table "namespaces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "path"
    t.string "type"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.datetime "deleted_at"
    t.jsonb "metadata_summary", default: {}
    t.uuid "owner_id"
    t.uuid "parent_id"
    t.string "puid", null: false
    t.index ["created_at"], name: "index_namespaces_on_created_at"
    t.index ["deleted_at"], name: "index_namespaces_on_deleted_at"
    t.index ["metadata_summary"], name: "index_namespaces_on_metadata_summary", using: :gin
    t.index ["owner_id"], name: "index_namespaces_on_owner_id"
    t.index ["parent_id"], name: "index_namespaces_on_parent_id"
    t.index ["puid"], name: "index_namespaces_on_puid", unique: true
  end

  create_table "personal_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "scopes"
    t.string "name"
    t.boolean "revoked", default: false, null: false
    t.date "expires_at"
    t.string "token_digest"
    t.datetime "last_used_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.datetime "deleted_at"
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_personal_access_tokens_on_created_at"
    t.index ["deleted_at"], name: "index_personal_access_tokens_on_deleted_at"
    t.index ["token_digest"], name: "index_personal_access_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_personal_access_tokens_on_user_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid "creator_id", null: false
    t.uuid "namespace_id", null: false
    t.index ["created_at"], name: "index_projects_on_created_at"
    t.index ["creator_id"], name: "index_projects_on_creator_id"
    t.index ["deleted_at"], name: "index_projects_on_deleted_at"
    t.index ["namespace_id"], name: "index_projects_on_namespace_id"
  end

  create_table "routes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "path"
    t.string "name"
    t.string "source_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid "source_id", null: false
    t.index ["created_at"], name: "index_routes_on_created_at"
    t.index ["deleted_at"], name: "index_routes_on_deleted_at"
    t.index ["name"], name: "index_routes_on_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["path"], name: "index_routes_on_path", unique: true, where: "(deleted_at IS NULL)"
    t.index ["source_id"], name: "index_routes_on_source_id"
  end

  create_table "samples", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "log_data"
    t.datetime "deleted_at"
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "metadata_provenance", default: {}, null: false
    t.string "puid", null: false
    t.uuid "project_id", null: false
    t.datetime "attachments_updated_at"
    t.index ["created_at"], name: "index_samples_on_created_at"
    t.index ["deleted_at"], name: "index_samples_on_deleted_at"
    t.index ["metadata"], name: "index_samples_on_metadata", using: :gin
    t.index ["metadata_provenance"], name: "index_samples_on_metadata_provenance", using: :gin
    t.index ["project_id"], name: "index_samples_on_project_id"
    t.index ["puid"], name: "index_samples_on_puid", unique: true
  end

  create_table "samples_workflow_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "samplesheet_params", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "workflow_execution_id"
    t.uuid "sample_id"
    t.datetime "attachments_updated_at"
    t.jsonb "metadata", default: {}, null: false
    t.index ["created_at"], name: "index_samples_workflow_executions_on_created_at"
    t.index ["sample_id"], name: "index_samples_workflow_executions_on_sample_id"
    t.index ["workflow_execution_id"], name: "index_samples_workflow_executions_on_workflow_execution_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.jsonb "log_data"
    t.datetime "deleted_at"
    t.string "first_name"
    t.string "last_name"
    t.string "locale", default: "en"
    t.integer "user_type", default: 0
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(deleted_at IS NULL)"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "workflow_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "metadata", default: {"workflow_name"=>"", "workflow_version"=>""}, null: false
    t.jsonb "workflow_params", default: {}, null: false
    t.string "workflow_type"
    t.string "workflow_type_version"
    t.string "workflow_engine"
    t.string "workflow_engine_version"
    t.jsonb "workflow_engine_parameters", default: {}, null: false
    t.string "workflow_url"
    t.string "run_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "submitter_id", null: false
    t.datetime "attachments_updated_at"
    t.string "blob_run_directory"
    t.boolean "email_notification", default: false, null: false
    t.boolean "update_samples", default: false, null: false
    t.integer "state"
    t.jsonb "tags", default: {}, null: false
    t.index ["created_at"], name: "index_workflow_executions_on_created_at"
    t.index ["state"], name: "index_workflow_executions_on_state"
    t.index ["submitter_id"], name: "index_workflow_executions_on_submitter_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "data_exports", "users"
  add_foreign_key "members", "namespaces"
  add_foreign_key "members", "users"
  add_foreign_key "namespace_group_links", "namespaces"
  add_foreign_key "namespaces", "users", column: "owner_id"
  add_foreign_key "personal_access_tokens", "users"
  add_foreign_key "projects", "namespaces"
  add_foreign_key "projects", "users", column: "creator_id"
  add_foreign_key "routes", "namespaces", column: "source_id"
  add_foreign_key "samples", "projects"
  add_foreign_key "samples_workflow_executions", "samples"
  add_foreign_key "samples_workflow_executions", "workflow_executions"
  add_foreign_key "workflow_executions", "users", column: "submitter_id"
  create_function :logidze_capture_exception, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_capture_exception(error_data jsonb)
       RETURNS boolean
       LANGUAGE plpgsql
      AS $function$
        -- version: 1
      BEGIN
        -- Feel free to change this function to change Logidze behavior on exception.
        --
        -- Return `false` to raise exception or `true` to commit record changes.
        --
        -- `error_data` contains:
        --   - returned_sqlstate
        --   - message_text
        --   - pg_exception_detail
        --   - pg_exception_hint
        --   - pg_exception_context
        --   - schema_name
        --   - table_name
        -- Learn more about available keys:
        -- https://www.postgresql.org/docs/9.6/plpgsql-control-structures.html#PLPGSQL-EXCEPTION-DIAGNOSTICS-VALUES
        --

        return false;
      END;
      $function$
  SQL
  create_function :logidze_compact_history, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_compact_history(log_data jsonb, cutoff integer DEFAULT 1)
       RETURNS jsonb
       LANGUAGE plpgsql
      AS $function$
        -- version: 1
        DECLARE
          merged jsonb;
        BEGIN
          LOOP
            merged := jsonb_build_object(
              'ts',
              log_data#>'{h,1,ts}',
              'v',
              log_data#>'{h,1,v}',
              'c',
              (log_data#>'{h,0,c}') || (log_data#>'{h,1,c}')
            );

            IF (log_data#>'{h,1}' ? 'm') THEN
              merged := jsonb_set(merged, ARRAY['m'], log_data#>'{h,1,m}');
            END IF;

            log_data := jsonb_set(
              log_data,
              '{h}',
              jsonb_set(
                log_data->'h',
                '{1}',
                merged
              ) - 0
            );

            cutoff := cutoff - 1;

            EXIT WHEN cutoff <= 0;
          END LOOP;

          return log_data;
        END;
      $function$
  SQL
  create_function :logidze_filter_keys, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_filter_keys(obj jsonb, keys text[], include_columns boolean DEFAULT false)
       RETURNS jsonb
       LANGUAGE plpgsql
      AS $function$
        -- version: 1
        DECLARE
          res jsonb;
          key text;
        BEGIN
          res := '{}';

          IF include_columns THEN
            FOREACH key IN ARRAY keys
            LOOP
              IF obj ? key THEN
                res = jsonb_insert(res, ARRAY[key], obj->key);
              END IF;
            END LOOP;
          ELSE
            res = obj;
            FOREACH key IN ARRAY keys
            LOOP
              res = res - key;
            END LOOP;
          END IF;

          RETURN res;
        END;
      $function$
  SQL
  create_function :logidze_logger, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_logger()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
        -- version: 3
        DECLARE
          changes jsonb;
          version jsonb;
          snapshot jsonb;
          new_v integer;
          size integer;
          history_limit integer;
          debounce_time integer;
          current_version integer;
          k text;
          iterator integer;
          item record;
          columns text[];
          include_columns boolean;
          ts timestamp with time zone;
          ts_column text;
          err_sqlstate text;
          err_message text;
          err_detail text;
          err_hint text;
          err_context text;
          err_table_name text;
          err_schema_name text;
          err_jsonb jsonb;
          err_captured boolean;
        BEGIN
          ts_column := NULLIF(TG_ARGV[1], 'null');
          columns := NULLIF(TG_ARGV[2], 'null');
          include_columns := NULLIF(TG_ARGV[3], 'null');

          IF TG_OP = 'INSERT' THEN
            IF columns IS NOT NULL THEN
              snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column, columns, include_columns);
            ELSE
              snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column);
            END IF;

            IF snapshot#>>'{h, -1, c}' != '{}' THEN
              NEW.log_data := snapshot;
            END IF;

          ELSIF TG_OP = 'UPDATE' THEN

            IF OLD.log_data is NULL OR OLD.log_data = '{}'::jsonb THEN
              IF columns IS NOT NULL THEN
                snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column, columns, include_columns);
              ELSE
                snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column);
              END IF;

              IF snapshot#>>'{h, -1, c}' != '{}' THEN
                NEW.log_data := snapshot;
              END IF;
              RETURN NEW;
            END IF;

            history_limit := NULLIF(TG_ARGV[0], 'null');
            debounce_time := NULLIF(TG_ARGV[4], 'null');

            current_version := (NEW.log_data->>'v')::int;

            IF ts_column IS NULL THEN
              ts := statement_timestamp();
            ELSE
              ts := (to_jsonb(NEW.*)->>ts_column)::timestamp with time zone;
              IF ts IS NULL OR ts = (to_jsonb(OLD.*)->>ts_column)::timestamp with time zone THEN
                ts := statement_timestamp();
              END IF;
            END IF;

            IF to_jsonb(NEW.*) = to_jsonb(OLD.*) THEN
              RETURN NEW;
            END IF;

            IF current_version < (NEW.log_data#>>'{h,-1,v}')::int THEN
              iterator := 0;
              FOR item in SELECT * FROM jsonb_array_elements(NEW.log_data->'h')
              LOOP
                IF (item.value->>'v')::int > current_version THEN
                  NEW.log_data := jsonb_set(
                    NEW.log_data,
                    '{h}',
                    (NEW.log_data->'h') - iterator
                  );
                END IF;
                iterator := iterator + 1;
              END LOOP;
            END IF;

            changes := '{}';

            IF (coalesce(current_setting('logidze.full_snapshot', true), '') = 'on') THEN
              BEGIN
                changes = hstore_to_jsonb_loose(hstore(NEW.*));
              EXCEPTION
                WHEN NUMERIC_VALUE_OUT_OF_RANGE THEN
                  changes = row_to_json(NEW.*)::jsonb;
                  FOR k IN (SELECT key FROM jsonb_each(changes))
                  LOOP
                    IF jsonb_typeof(changes->k) = 'object' THEN
                      changes = jsonb_set(changes, ARRAY[k], to_jsonb(changes->>k));
                    END IF;
                  END LOOP;
              END;
            ELSE
              BEGIN
                changes = hstore_to_jsonb_loose(
                      hstore(NEW.*) - hstore(OLD.*)
                  );
              EXCEPTION
                WHEN NUMERIC_VALUE_OUT_OF_RANGE THEN
                  changes = (SELECT
                    COALESCE(json_object_agg(key, value), '{}')::jsonb
                    FROM
                    jsonb_each(row_to_json(NEW.*)::jsonb)
                    WHERE NOT jsonb_build_object(key, value) <@ row_to_json(OLD.*)::jsonb);
                  FOR k IN (SELECT key FROM jsonb_each(changes))
                  LOOP
                    IF jsonb_typeof(changes->k) = 'object' THEN
                      changes = jsonb_set(changes, ARRAY[k], to_jsonb(changes->>k));
                    END IF;
                  END LOOP;
              END;
            END IF;

            changes = changes - 'log_data';

            IF columns IS NOT NULL THEN
              changes = logidze_filter_keys(changes, columns, include_columns);
            END IF;

            IF changes = '{}' THEN
              RETURN NEW;
            END IF;

            new_v := (NEW.log_data#>>'{h,-1,v}')::int + 1;

            size := jsonb_array_length(NEW.log_data->'h');
            version := logidze_version(new_v, changes, ts);

            IF (
              debounce_time IS NOT NULL AND
              (version->>'ts')::bigint - (NEW.log_data#>'{h,-1,ts}')::text::bigint <= debounce_time
            ) THEN
              -- merge new version with the previous one
              new_v := (NEW.log_data#>>'{h,-1,v}')::int;
              version := logidze_version(new_v, (NEW.log_data#>'{h,-1,c}')::jsonb || changes, ts);
              -- remove the previous version from log
              NEW.log_data := jsonb_set(
                NEW.log_data,
                '{h}',
                (NEW.log_data->'h') - (size - 1)
              );
            END IF;

            NEW.log_data := jsonb_set(
              NEW.log_data,
              ARRAY['h', size::text],
              version,
              true
            );

            NEW.log_data := jsonb_set(
              NEW.log_data,
              '{v}',
              to_jsonb(new_v)
            );

            IF history_limit IS NOT NULL AND history_limit <= size THEN
              NEW.log_data := logidze_compact_history(NEW.log_data, size - history_limit + 1);
            END IF;
          END IF;

          return NEW;
        EXCEPTION
          WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS err_sqlstate = RETURNED_SQLSTATE,
                                    err_message = MESSAGE_TEXT,
                                    err_detail = PG_EXCEPTION_DETAIL,
                                    err_hint = PG_EXCEPTION_HINT,
                                    err_context = PG_EXCEPTION_CONTEXT,
                                    err_schema_name = SCHEMA_NAME,
                                    err_table_name = TABLE_NAME;
            err_jsonb := jsonb_build_object(
              'returned_sqlstate', err_sqlstate,
              'message_text', err_message,
              'pg_exception_detail', err_detail,
              'pg_exception_hint', err_hint,
              'pg_exception_context', err_context,
              'schema_name', err_schema_name,
              'table_name', err_table_name
            );
            err_captured = logidze_capture_exception(err_jsonb);
            IF err_captured THEN
              return NEW;
            ELSE
              RAISE;
            END IF;
        END;
      $function$
  SQL
  create_function :logidze_snapshot, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_snapshot(item jsonb, ts_column text DEFAULT NULL::text, columns text[] DEFAULT NULL::text[], include_columns boolean DEFAULT false)
       RETURNS jsonb
       LANGUAGE plpgsql
      AS $function$
        -- version: 3
        DECLARE
          ts timestamp with time zone;
          k text;
        BEGIN
          item = item - 'log_data';
          IF ts_column IS NULL THEN
            ts := statement_timestamp();
          ELSE
            ts := coalesce((item->>ts_column)::timestamp with time zone, statement_timestamp());
          END IF;

          IF columns IS NOT NULL THEN
            item := logidze_filter_keys(item, columns, include_columns);
          END IF;

          FOR k IN (SELECT key FROM jsonb_each(item))
          LOOP
            IF jsonb_typeof(item->k) = 'object' THEN
               item := jsonb_set(item, ARRAY[k], to_jsonb(item->>k));
            END IF;
          END LOOP;

          return json_build_object(
            'v', 1,
            'h', jsonb_build_array(
                    logidze_version(1, item, ts)
                  )
            );
        END;
      $function$
  SQL
  create_function :logidze_version, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.logidze_version(v bigint, data jsonb, ts timestamp with time zone)
       RETURNS jsonb
       LANGUAGE plpgsql
      AS $function$
        -- version: 2
        DECLARE
          buf jsonb;
        BEGIN
          data = data - 'log_data';
          buf := jsonb_build_object(
                    'ts',
                    (extract(epoch from ts) * 1000)::bigint,
                    'v',
                    v,
                    'c',
                    data
                    );
          IF coalesce(current_setting('logidze.meta', true), '') <> '' THEN
            buf := jsonb_insert(buf, '{m}', current_setting('logidze.meta')::jsonb);
          END IF;
          RETURN buf;
        END;
      $function$
  SQL


  create_trigger :logidze_on_users, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_users BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_namespaces, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_namespaces BEFORE INSERT OR UPDATE ON public.namespaces FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at', '{created_at,metadata_summary,updated_at}')
  SQL
  create_trigger :logidze_on_members, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_members BEFORE INSERT OR UPDATE ON public.members FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_samples, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_samples BEFORE INSERT OR UPDATE ON public.samples FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at', '{created_at,metadata_provenance,updated_at,attachments_updated_at}')
  SQL
  create_trigger :logidze_on_personal_access_tokens, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_personal_access_tokens BEFORE INSERT OR UPDATE ON public.personal_access_tokens FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_namespace_group_links, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_namespace_group_links BEFORE INSERT OR UPDATE ON public.namespace_group_links FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_attachments, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_attachments BEFORE INSERT OR UPDATE ON public.attachments FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_data_exports, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_data_exports BEFORE INSERT OR UPDATE ON public.data_exports FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
  create_trigger :logidze_on_namespace_bots, sql_definition: <<-SQL
      CREATE TRIGGER logidze_on_namespace_bots BEFORE INSERT OR UPDATE ON public.namespace_bots FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION logidze_logger('null', 'updated_at')
  SQL
end
