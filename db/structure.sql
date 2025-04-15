SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: numeric; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."numeric" (provider = icu, locale = 'en-u-kn-true');


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: logidze_capture_exception(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_capture_exception(error_data jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: logidze_compact_history(jsonb, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_compact_history(log_data jsonb, cutoff integer DEFAULT 1) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: logidze_filter_keys(jsonb, text[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_filter_keys(obj jsonb, keys text[], include_columns boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: logidze_logger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_logger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: logidze_snapshot(jsonb, text, text[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_snapshot(item jsonb, ts_column text DEFAULT NULL::text, columns text[] DEFAULT NULL::text[], include_columns boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: logidze_version(bigint, jsonb, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_version(v bigint, data jsonb, ts timestamp with time zone) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    blob_id uuid NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    variation_digest character varying NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blob_id uuid NOT NULL
);


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trackable_type character varying,
    trackable_id uuid,
    owner_type character varying,
    owner_id uuid,
    key character varying,
    parameters text,
    recipient_type character varying,
    recipient_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    attachable_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attachable_id uuid NOT NULL,
    puid character varying NOT NULL
);


--
-- Name: automated_workflow_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.automated_workflow_executions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    created_by_id uuid NOT NULL,
    metadata jsonb DEFAULT '{"workflow_name": "", "workflow_version": ""}'::jsonb NOT NULL,
    workflow_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    email_notification boolean DEFAULT false NOT NULL,
    update_samples boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    name character varying,
    disabled boolean DEFAULT false NOT NULL
);


--
-- Name: data_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_exports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying,
    export_type character varying NOT NULL,
    status character varying NOT NULL,
    export_parameters jsonb DEFAULT '{}'::jsonb NOT NULL,
    expires_at timestamp(6) without time zone,
    email_notification boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    user_id uuid NOT NULL,
    manifest jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    access_level integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    deleted_at timestamp(6) without time zone,
    expires_at date,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    namespace_id uuid NOT NULL,
    created_by_id uuid NOT NULL
);


--
-- Name: metadata_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid,
    created_by_id uuid NOT NULL,
    name character varying,
    description character varying,
    fields jsonb DEFAULT '[]'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb
);


--
-- Name: namespace_bots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_bots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    namespace_id uuid NOT NULL,
    deleted_at timestamp(6) without time zone,
    log_data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: namespace_group_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_group_links (
    expires_at date,
    group_access_level integer NOT NULL,
    namespace_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    deleted_at timestamp(6) without time zone,
    log_data jsonb,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    namespace_id uuid NOT NULL
);


--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespaces (
    name character varying COLLATE public."numeric",
    path character varying,
    type character varying,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    deleted_at timestamp(6) without time zone,
    metadata_summary jsonb DEFAULT '{}'::jsonb,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_id uuid,
    parent_id uuid,
    puid character varying NOT NULL,
    attachments_updated_at timestamp(6) without time zone,
    samples_count integer DEFAULT 0
);


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_access_tokens (
    scopes character varying,
    name character varying,
    revoked boolean DEFAULT false NOT NULL,
    expires_at date,
    token_digest character varying,
    last_used_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    deleted_at timestamp(6) without time zone,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    deleted_at timestamp(6) without time zone,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    creator_id uuid NOT NULL,
    namespace_id uuid NOT NULL,
    samples_count integer
);


--
-- Name: routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.routes (
    path character varying,
    name character varying,
    source_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    deleted_at timestamp(6) without time zone,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_id uuid NOT NULL
);


--
-- Name: samples; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.samples (
    name character varying COLLATE public."numeric",
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_data jsonb,
    deleted_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata_provenance jsonb DEFAULT '{}'::jsonb NOT NULL,
    puid character varying NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    attachments_updated_at timestamp(6) without time zone
);


--
-- Name: samples_workflow_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.samples_workflow_executions (
    samplesheet_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_execution_id uuid,
    sample_id uuid,
    attachments_updated_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    session_id character varying NOT NULL,
    data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    provider character varying,
    uid character varying,
    log_data jsonb,
    deleted_at timestamp(6) without time zone,
    first_name character varying,
    last_name character varying,
    locale character varying DEFAULT 'en'::character varying,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_type integer DEFAULT 0
);


--
-- Name: workflow_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_executions (
    metadata jsonb DEFAULT '{"workflow_name": "", "workflow_version": ""}'::jsonb NOT NULL,
    workflow_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    workflow_type character varying,
    workflow_type_version character varying,
    workflow_engine character varying,
    workflow_engine_version character varying,
    workflow_engine_parameters jsonb DEFAULT '{}'::jsonb NOT NULL,
    workflow_url character varying,
    run_id character varying,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    submitter_id uuid NOT NULL,
    attachments_updated_at timestamp(6) without time zone,
    blob_run_directory character varying,
    email_notification boolean DEFAULT false NOT NULL,
    update_samples boolean DEFAULT false NOT NULL,
    http_error_code integer,
    tags jsonb DEFAULT '{}'::jsonb NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    name character varying,
    namespace_id uuid,
    cleaned boolean DEFAULT false NOT NULL,
    shared_with_namespace boolean DEFAULT false NOT NULL,
    log_data jsonb
);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: automated_workflow_executions automated_workflow_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automated_workflow_executions
    ADD CONSTRAINT automated_workflow_executions_pkey PRIMARY KEY (id);


--
-- Name: data_exports data_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_exports
    ADD CONSTRAINT data_exports_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: metadata_templates metadata_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_templates
    ADD CONSTRAINT metadata_templates_pkey PRIMARY KEY (id);


--
-- Name: namespace_bots namespace_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_bots
    ADD CONSTRAINT namespace_bots_pkey PRIMARY KEY (id);


--
-- Name: namespace_group_links namespace_group_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_group_links
    ADD CONSTRAINT namespace_group_links_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: samples samples_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples
    ADD CONSTRAINT samples_pkey PRIMARY KEY (id);


--
-- Name: samples_workflow_executions samples_workflow_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples_workflow_executions
    ADD CONSTRAINT samples_workflow_executions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workflow_executions workflow_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_executions
    ADD CONSTRAINT workflow_executions_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_created_at ON public.active_storage_attachments USING btree (created_at);


--
-- Name: index_active_storage_attachments_on_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_record_id ON public.active_storage_attachments USING btree (record_id);


--
-- Name: index_active_storage_blobs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_blobs_on_created_at ON public.active_storage_blobs USING btree (created_at);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_variant_records_on_blob_id ON public.active_storage_variant_records USING btree (blob_id);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_activities_on_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_owner ON public.activities USING btree (owner_type, owner_id);


--
-- Name: index_activities_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_owner_id_and_owner_type ON public.activities USING btree (owner_id, owner_type);


--
-- Name: index_activities_on_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_recipient ON public.activities USING btree (recipient_type, recipient_id);


--
-- Name: index_activities_on_recipient_id_and_recipient_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_recipient_id_and_recipient_type ON public.activities USING btree (recipient_id, recipient_type);


--
-- Name: index_activities_on_trackable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_trackable ON public.activities USING btree (trackable_type, trackable_id);


--
-- Name: index_activities_on_trackable_id_and_trackable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_trackable_id_and_trackable_type ON public.activities USING btree (trackable_id, trackable_type);


--
-- Name: index_attachments_on_attachable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_attachable_id ON public.attachments USING btree (attachable_id);


--
-- Name: index_attachments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_created_at ON public.attachments USING btree (created_at);


--
-- Name: index_attachments_on_metadata_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_metadata_ci ON public.attachments USING gin (((lower((metadata)::text))::jsonb));


--
-- Name: index_attachments_on_puid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_puid ON public.attachments USING btree (puid);


--
-- Name: index_automated_workflow_executions_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_automated_workflow_executions_on_created_by_id ON public.automated_workflow_executions USING btree (created_by_id);


--
-- Name: index_automated_workflow_executions_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_automated_workflow_executions_on_namespace_id ON public.automated_workflow_executions USING btree (namespace_id);


--
-- Name: index_bot_user_with_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bot_user_with_namespace ON public.namespace_bots USING btree (user_id, namespace_id);


--
-- Name: index_data_exports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_exports_on_created_at ON public.data_exports USING btree (created_at);


--
-- Name: index_data_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_exports_on_user_id ON public.data_exports USING btree (user_id);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_member_user_with_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_member_user_with_namespace ON public.members USING btree (user_id, namespace_id) WHERE (deleted_at IS NULL);


--
-- Name: index_members_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_created_at ON public.members USING btree (created_at);


--
-- Name: index_members_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_created_by_id ON public.members USING btree (created_by_id);


--
-- Name: index_members_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_deleted_at ON public.members USING btree (deleted_at);


--
-- Name: index_members_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_expires_at ON public.members USING btree (expires_at);


--
-- Name: index_members_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_namespace_id ON public.members USING btree (namespace_id);


--
-- Name: index_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_user_id ON public.members USING btree (user_id);


--
-- Name: index_metadata_templates_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_templates_on_created_by_id ON public.metadata_templates USING btree (created_by_id);


--
-- Name: index_metadata_templates_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metadata_templates_on_namespace_id ON public.metadata_templates USING btree (namespace_id);


--
-- Name: index_namespace_bots_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_bots_on_deleted_at ON public.namespace_bots USING btree (deleted_at);


--
-- Name: index_namespace_group_link_user_with_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespace_group_link_user_with_namespace ON public.namespace_group_links USING btree (group_id, namespace_id) WHERE (deleted_at IS NULL);


--
-- Name: index_namespace_group_links_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_group_links_on_created_at ON public.namespace_group_links USING btree (created_at);


--
-- Name: index_namespace_group_links_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_group_links_on_deleted_at ON public.namespace_group_links USING btree (deleted_at);


--
-- Name: index_namespace_group_links_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_group_links_on_group_id ON public.namespace_group_links USING btree (group_id);


--
-- Name: index_namespace_group_links_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_group_links_on_namespace_id ON public.namespace_group_links USING btree (namespace_id);


--
-- Name: index_namespaces_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_created_at ON public.namespaces USING btree (created_at);


--
-- Name: index_namespaces_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_deleted_at ON public.namespaces USING btree (deleted_at);


--
-- Name: index_namespaces_on_metadata_summary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_metadata_summary ON public.namespaces USING gin (metadata_summary);


--
-- Name: index_namespaces_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_owner_id ON public.namespaces USING btree (owner_id);


--
-- Name: index_namespaces_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_parent_id ON public.namespaces USING btree (parent_id);


--
-- Name: index_namespaces_on_puid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespaces_on_puid ON public.namespaces USING btree (puid);


--
-- Name: index_personal_access_tokens_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_personal_access_tokens_on_created_at ON public.personal_access_tokens USING btree (created_at);


--
-- Name: index_personal_access_tokens_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_personal_access_tokens_on_deleted_at ON public.personal_access_tokens USING btree (deleted_at);


--
-- Name: index_personal_access_tokens_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_personal_access_tokens_on_token_digest ON public.personal_access_tokens USING btree (token_digest);


--
-- Name: index_personal_access_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_personal_access_tokens_on_user_id ON public.personal_access_tokens USING btree (user_id);


--
-- Name: index_projects_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_created_at ON public.projects USING btree (created_at);


--
-- Name: index_projects_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_creator_id ON public.projects USING btree (creator_id);


--
-- Name: index_projects_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_deleted_at ON public.projects USING btree (deleted_at);


--
-- Name: index_projects_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_namespace_id ON public.projects USING btree (namespace_id);


--
-- Name: index_routes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routes_on_created_at ON public.routes USING btree (created_at);


--
-- Name: index_routes_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routes_on_deleted_at ON public.routes USING btree (deleted_at);


--
-- Name: index_routes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_routes_on_name ON public.routes USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: index_routes_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_routes_on_path ON public.routes USING btree (path) WHERE (deleted_at IS NULL);


--
-- Name: index_routes_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routes_on_source_id ON public.routes USING btree (source_id);


--
-- Name: index_sample_name_with_project; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sample_name_with_project ON public.samples USING btree (name, project_id) WHERE (deleted_at IS NULL);


--
-- Name: index_samples_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_on_created_at ON public.samples USING btree (created_at);


--
-- Name: index_samples_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_on_deleted_at ON public.samples USING btree (deleted_at);


--
-- Name: index_samples_on_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_samples_on_id_and_project_id ON public.samples USING btree (id, project_id);


--
-- Name: index_samples_on_metadata_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_on_metadata_ci ON public.samples USING gin (((lower((metadata)::text))::jsonb));


--
-- Name: index_samples_on_metadata_provenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_on_metadata_provenance ON public.samples USING gin (metadata_provenance);


--
-- Name: index_samples_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_on_project_id ON public.samples USING btree (project_id);


--
-- Name: index_samples_on_puid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_samples_on_puid ON public.samples USING btree (puid);


--
-- Name: index_samples_workflow_executions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_workflow_executions_on_created_at ON public.samples_workflow_executions USING btree (created_at);


--
-- Name: index_samples_workflow_executions_on_sample_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_workflow_executions_on_sample_id ON public.samples_workflow_executions USING btree (sample_id);


--
-- Name: index_samples_workflow_executions_on_workflow_execution_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_samples_workflow_executions_on_workflow_execution_id ON public.samples_workflow_executions USING btree (workflow_execution_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_template_fields_with_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_template_fields_with_namespace ON public.metadata_templates USING btree (fields, namespace_id) WHERE (deleted_at IS NULL);


--
-- Name: index_template_name_with_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_template_name_with_namespace ON public.metadata_templates USING btree (namespace_id, name) WHERE (deleted_at IS NULL);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON public.users USING btree (created_at);


--
-- Name: index_users_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_deleted_at ON public.users USING btree (deleted_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email) WHERE (deleted_at IS NULL);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token) WHERE (deleted_at IS NULL);


--
-- Name: index_workflow_executions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_executions_on_created_at ON public.workflow_executions USING btree (created_at);


--
-- Name: index_workflow_executions_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_executions_on_namespace_id ON public.workflow_executions USING btree (namespace_id);


--
-- Name: index_workflow_executions_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_executions_on_state ON public.workflow_executions USING btree (state);


--
-- Name: index_workflow_executions_on_submitter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_executions_on_submitter_id ON public.workflow_executions USING btree (submitter_id);


--
-- Name: attachments logidze_on_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_attachments BEFORE INSERT OR UPDATE ON public.attachments FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: automated_workflow_executions logidze_on_automated_workflow_executions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_automated_workflow_executions BEFORE INSERT OR UPDATE ON public.automated_workflow_executions FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: data_exports logidze_on_data_exports; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_data_exports BEFORE INSERT OR UPDATE ON public.data_exports FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: members logidze_on_members; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_members BEFORE INSERT OR UPDATE ON public.members FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: metadata_templates logidze_on_metadata_templates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_metadata_templates BEFORE INSERT OR UPDATE ON public.metadata_templates FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: namespace_bots logidze_on_namespace_bots; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_namespace_bots BEFORE INSERT OR UPDATE ON public.namespace_bots FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: namespace_group_links logidze_on_namespace_group_links; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_namespace_group_links BEFORE INSERT OR UPDATE ON public.namespace_group_links FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: namespaces logidze_on_namespaces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_namespaces BEFORE INSERT OR UPDATE ON public.namespaces FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at', '{created_at,metadata_summary,updated_at,attachments_updated_at}');


--
-- Name: personal_access_tokens logidze_on_personal_access_tokens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_personal_access_tokens BEFORE INSERT OR UPDATE ON public.personal_access_tokens FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at', '{last_used_at}');


--
-- Name: samples logidze_on_samples; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_samples BEFORE INSERT OR UPDATE ON public.samples FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at', '{created_at,metadata_provenance,updated_at,attachments_updated_at}');


--
-- Name: users logidze_on_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_users BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at');


--
-- Name: workflow_executions logidze_on_workflow_executions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_workflow_executions BEFORE INSERT OR UPDATE ON public.workflow_executions FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('null', 'updated_at', '{run_id,name,state,deleted_at}', 'true');


--
-- Name: projects fk_rails_03ec10b0d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_03ec10b0d3 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: personal_access_tokens fk_rails_08903b8f38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT fk_rails_08903b8f38 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: projects fk_rails_0e800909ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_0e800909ce FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: namespace_group_links fk_rails_13e2b1d2b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_group_links
    ADD CONSTRAINT fk_rails_13e2b1d2b3 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: members fk_rails_2e88fb7ce9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_2e88fb7ce9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: automated_workflow_executions fk_rails_4767fc7317; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automated_workflow_executions
    ADD CONSTRAINT fk_rails_4767fc7317 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: workflow_executions fk_rails_495e63f7d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_executions
    ADD CONSTRAINT fk_rails_495e63f7d2 FOREIGN KEY (submitter_id) REFERENCES public.users(id);


--
-- Name: data_exports fk_rails_5408e45594; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_exports
    ADD CONSTRAINT fk_rails_5408e45594 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: members fk_rails_57c4549f0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_57c4549f0c FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: samples fk_rails_592ee49822; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples
    ADD CONSTRAINT fk_rails_592ee49822 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: samples_workflow_executions fk_rails_612b2b3c68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples_workflow_executions
    ADD CONSTRAINT fk_rails_612b2b3c68 FOREIGN KEY (workflow_execution_id) REFERENCES public.workflow_executions(id);


--
-- Name: automated_workflow_executions fk_rails_64f0b6275c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automated_workflow_executions
    ADD CONSTRAINT fk_rails_64f0b6275c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: namespaces fk_rails_a4d67b8880; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT fk_rails_a4d67b8880 FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: metadata_templates fk_rails_bad8409684; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_templates
    ADD CONSTRAINT fk_rails_bad8409684 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: routes fk_rails_df2c61f7cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT fk_rails_df2c61f7cb FOREIGN KEY (source_id) REFERENCES public.namespaces(id);


--
-- Name: samples_workflow_executions fk_rails_e10b6b255f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples_workflow_executions
    ADD CONSTRAINT fk_rails_e10b6b255f FOREIGN KEY (sample_id) REFERENCES public.samples(id);


--
-- Name: metadata_templates fk_rails_f2cf231357; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_templates
    ADD CONSTRAINT fk_rails_f2cf231357 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: workflow_executions fk_rails_f53eb324f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_executions
    ADD CONSTRAINT fk_rails_f53eb324f1 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20250414172424'),
('20250219172718'),
('20250219002757'),
('20250219001422'),
('20250218231716'),
('20250218231203'),
('20250218230758'),
('20250216203841'),
('20250211183505'),
('20250210214118'),
('20250206192359'),
('20250109162252'),
('20250108200329'),
('20250107194839'),
('20250106153442'),
('20241120173553'),
('20241017164233'),
('20241004162923'),
('20241003193845'),
('20241003125314'),
('20240925230422'),
('20240925155747'),
('20240912193934'),
('20240912152940'),
('20240823190536'),
('20240823185615'),
('20240822144703'),
('20240821134505'),
('20240821130727'),
('20240815144329'),
('20240815144328'),
('20240815144327'),
('20240730161412'),
('20240711160907'),
('20240523185248'),
('20240517134556'),
('20240508171227'),
('20240501131412'),
('20240426160617'),
('20240426160117'),
('20240426144141'),
('20240425163945'),
('20240425141711'),
('20240424190352'),
('20240423155817'),
('20240423155416'),
('20240422160144'),
('20240418180337'),
('20240416194657'),
('20240408204851'),
('20240408201453'),
('20240404150143'),
('20240328145629'),
('20240325190420'),
('20240322161334'),
('20240322161330'),
('20240320201313'),
('20240313142828'),
('20240311204219'),
('20240311204201'),
('20240311152839'),
('20240311152411'),
('20240311145704'),
('20240229165646'),
('20240223174555'),
('20240223174332'),
('20240223173135'),
('20240209155131'),
('20240205175935'),
('20240124170054'),
('20240122144035'),
('20240111163859'),
('20231121200855'),
('20231110010313'),
('20231110010253'),
('20231030151719'),
('20231025155037'),
('20230929194603'),
('20230926133927'),
('20230913011402'),
('20230830152823'),
('20230830152213'),
('20230727133120'),
('20230713163258'),
('20230713163121'),
('20230713162059'),
('20230630162646'),
('20230628145212'),
('20230626190220'),
('20230622204135'),
('20230622175923'),
('20230601145011'),
('20230530205431'),
('20230530204753'),
('20230530204734'),
('20230530204615'),
('20230530204607'),
('20230530204556'),
('20230519155854'),
('20230519155844'),
('20230519155837'),
('20230519155734'),
('20230519155615'),
('20230519155460'),
('20230519155459'),
('20230426174630'),
('20230413221752'),
('20230327202710'),
('20230316180414'),
('20230228214717'),
('20230227172418'),
('20230209163157'),
('20230208193900'),
('20230208151744');

