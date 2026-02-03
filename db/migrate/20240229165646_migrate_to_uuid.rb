# frozen_string_literal: true

# migration to change primary IDs to UUIDs
class MigrateToUuid < ActiveRecord::Migration[7.1] # rubocop:disable Metrics/ClassLength
  def up # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    add_column :attachments, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :samples_workflow_executions, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :workflow_executions, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :active_storage_attachments, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :active_storage_blobs, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :active_storage_variant_records, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :users, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :members, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :namespace_group_links, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :namespaces, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :personal_access_tokens, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :projects, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :routes, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }
    add_column :samples, :uuid, :uuid, null: false, default: -> { 'gen_random_uuid()' }

    # Add UUID columns for associations
    add_column :samples_workflow_executions, :workflow_execution_uuid, :uuid
    add_column :samples_workflow_executions, :sample_uuid, :uuid
    add_column :workflow_executions, :submitter_uuid, :uuid
    add_column :active_storage_attachments, :record_uuid, :uuid
    add_column :active_storage_attachments, :blob_uuid, :uuid
    add_column :active_storage_variant_records, :blob_uuid, :uuid
    add_column :attachments, :attachable_uuid, :uuid
    add_column :data_exports, :user_uuid, :uuid
    add_column :members, :user_uuid, :uuid
    add_column :members, :namespace_uuid, :uuid
    add_column :members, :created_by_uuid, :uuid
    add_column :namespace_group_links, :group_uuid, :uuid
    add_column :namespace_group_links, :namespace_uuid, :uuid
    add_column :namespaces, :owner_uuid, :uuid
    add_column :namespaces, :parent_uuid, :uuid
    add_column :personal_access_tokens, :user_uuid, :uuid
    add_column :projects, :creator_uuid, :uuid
    add_column :projects, :namespace_uuid, :uuid
    add_column :routes, :source_uuid, :uuid
    add_column :samples, :project_uuid, :uuid

    # Populate UUID columns for associations
    execute <<~SQL.squish
      UPDATE samples_workflow_executions SET workflow_execution_uuid = workflow_executions.uuid
      FROM workflow_executions WHERE samples_workflow_executions.workflow_execution_id = workflow_executions.id;

      UPDATE samples_workflow_executions SET sample_uuid = samples.uuid
      FROM samples WHERE samples_workflow_executions.sample_id = samples.id;

      UPDATE workflow_executions SET submitter_uuid = users.uuid
      FROM users WHERE workflow_executions.submitter_id = users.id;

      UPDATE active_storage_attachments SET record_uuid = attachments.uuid
      FROM attachments WHERE active_storage_attachments.record_id = attachments.id
      and active_storage_attachments.record_type = 'Attachment';

      UPDATE active_storage_attachments SET record_uuid = workflow_executions.uuid
      FROM workflow_executions WHERE active_storage_attachments.record_id = workflow_executions.id
      and active_storage_attachments.record_type = 'WorkflowExecution';

      UPDATE active_storage_attachments SET record_uuid = samples_workflow_executions.uuid
      FROM samples_workflow_executions WHERE active_storage_attachments.record_id = samples_workflow_executions.id
      and active_storage_attachments.record_type = 'SamplesWorkflowExecution';

      UPDATE active_storage_attachments SET blob_uuid = active_storage_blobs.uuid
      FROM active_storage_blobs WHERE active_storage_attachments.blob_id = active_storage_blobs.id;

      UPDATE active_storage_variant_records SET blob_uuid = active_storage_blobs.uuid
      FROM active_storage_blobs WHERE active_storage_variant_records.blob_id = active_storage_blobs.id;

      UPDATE attachments SET attachable_uuid = samples.uuid
      FROM samples WHERE attachments.attachable_id = samples.id;

      UPDATE attachments SET metadata['associated_attachment_id'] = to_jsonb(a.uuid)
      FROM attachments a WHERE (attachments.metadata['associated_attachment_id'])::int = a.id;

      UPDATE data_exports SET user_uuid = users.uuid
      FROM users WHERE data_exports.user_id = users.id;

      UPDATE members SET user_uuid = users.uuid
      FROM users WHERE members.user_id = users.id;

      UPDATE members SET namespace_uuid = namespaces.uuid
      FROM namespaces WHERE members.namespace_id = namespaces.id;

      UPDATE members SET created_by_uuid = users.uuid
      FROM users WHERE members.created_by_id = users.id;

      UPDATE namespace_group_links SET group_uuid = namespaces.uuid
      FROM namespaces WHERE namespace_group_links.group_id = namespaces.id;

      UPDATE namespace_group_links SET namespace_uuid = namespaces.uuid
      FROM namespaces WHERE namespace_group_links.namespace_id = namespaces.id;

      UPDATE namespaces SET owner_uuid = users.uuid
      FROM users WHERE namespaces.owner_id = users.id;

      UPDATE namespaces SET parent_uuid = n.uuid
      FROM namespaces n WHERE namespaces.parent_id = n.id;

      UPDATE personal_access_tokens SET user_uuid = users.uuid
      FROM users WHERE personal_access_tokens.user_id = users.id;

      UPDATE projects SET creator_uuid = users.uuid
      FROM users WHERE projects.creator_id = users.id;

      UPDATE projects SET namespace_uuid = namespaces.uuid
      FROM namespaces WHERE projects.namespace_id = namespaces.id;

      UPDATE routes SET source_uuid = namespaces.uuid
      FROM namespaces WHERE routes.source_id = namespaces.id;

      UPDATE samples SET project_uuid = projects.uuid
      FROM projects WHERE samples.project_id = projects.id;

      WITH t as (
        SELECT s.id as id, jsonb_object_agg(metadata_key, s.metadata_provenance->metadata_key|| jsonb_object(array['id']::text[], array[u.uuid]::text[])) as updated_metadata_provenance
        FROM users u, samples s
        JOIN jsonb_object_keys(s.metadata_provenance) metadata_key ON true
        WHERE s.metadata_provenance->metadata_key->>'source' = 'user'
        AND (s.metadata_provenance->metadata_key->'id')::int = u.id
        GROUP BY s.id
      )
      UPDATE samples set metadata_provenance = metadata_provenance || t.updated_metadata_provenance
      FROM t
      WHERE samples.id = t.id;

      WITH t as (
        SELECT s.id as id, jsonb_object_agg(metadata_key, s.metadata_provenance->metadata_key|| jsonb_object(array['id']::text[], array[a.uuid]::text[])) as updated_metadata_provenance
        FROM workflow_executions a, samples s
        JOIN jsonb_object_keys(s.metadata_provenance) metadata_key ON true
        WHERE s.metadata_provenance->metadata_key->>'source' = 'analysis'
        AND (s.metadata_provenance->metadata_key->'id')::int = a.id
        GROUP BY s.id
      )
      UPDATE samples set metadata_provenance = metadata_provenance || t.updated_metadata_provenance
      FROM t
      WHERE samples.id = t.id;
    SQL

    change_column_null :samples_workflow_executions, :workflow_execution_uuid, true
    change_column_null :samples_workflow_executions, :sample_uuid, true
    change_column_null :workflow_executions, :submitter_uuid, false
    change_column_null :active_storage_attachments, :record_uuid, false
    change_column_null :active_storage_attachments, :blob_uuid, false
    change_column_null :active_storage_variant_records, :blob_uuid, false
    change_column_null :attachments, :attachable_uuid, false
    change_column_null :data_exports, :user_uuid, false
    change_column_null :members, :user_uuid, false
    change_column_null :members, :namespace_uuid, false
    change_column_null :members, :created_by_uuid, false
    change_column_null :namespace_group_links, :group_uuid, false
    change_column_null :namespace_group_links, :namespace_uuid, false
    change_column_null :namespaces, :owner_uuid, true
    change_column_null :namespaces, :parent_uuid, true
    change_column_null :personal_access_tokens, :user_uuid, false
    change_column_null :projects, :creator_uuid, false
    change_column_null :projects, :namespace_uuid, false
    change_column_null :routes, :source_uuid, false
    change_column_null :samples, :project_uuid, false

    # Migrate UUID to ID for associations
    remove_column :samples_workflow_executions, :workflow_execution_id
    remove_column :samples_workflow_executions, :sample_id
    remove_column :workflow_executions, :submitter_id
    remove_column :active_storage_attachments, :record_id
    remove_column :active_storage_attachments, :blob_id
    remove_column :active_storage_variant_records, :blob_id
    remove_column :attachments, :attachable_id
    remove_column :data_exports, :user_id
    remove_column :members, :user_id
    remove_column :members, :namespace_id
    remove_column :members, :created_by_id
    remove_column :namespace_group_links, :group_id
    remove_column :namespace_group_links, :namespace_id
    remove_column :namespaces, :owner_id
    remove_column :namespaces, :parent_id
    remove_column :personal_access_tokens, :user_id
    remove_column :projects, :creator_id
    remove_column :projects, :namespace_id
    remove_column :routes, :source_id
    remove_column :samples, :project_id

    rename_column :samples_workflow_executions, :workflow_execution_uuid, :workflow_execution_id
    rename_column :samples_workflow_executions, :sample_uuid, :sample_id
    rename_column :workflow_executions, :submitter_uuid, :submitter_id
    rename_column :active_storage_attachments, :record_uuid, :record_id
    rename_column :active_storage_attachments, :blob_uuid, :blob_id
    rename_column :active_storage_variant_records, :blob_uuid, :blob_id
    rename_column :attachments, :attachable_uuid, :attachable_id
    rename_column :data_exports, :user_uuid, :user_id
    rename_column :members, :user_uuid, :user_id
    rename_column :members, :namespace_uuid, :namespace_id
    rename_column :members, :created_by_uuid, :created_by_id
    rename_column :namespace_group_links, :group_uuid, :group_id
    rename_column :namespace_group_links, :namespace_uuid, :namespace_id
    rename_column :namespaces, :owner_uuid, :owner_id
    rename_column :namespaces, :parent_uuid, :parent_id
    rename_column :personal_access_tokens, :user_uuid, :user_id
    rename_column :projects, :creator_uuid, :creator_id
    rename_column :projects, :namespace_uuid, :namespace_id
    rename_column :routes, :source_uuid, :source_id
    rename_column :samples, :project_uuid, :project_id

    # Add indexes for associations
    add_index :samples_workflow_executions, :workflow_execution_id
    add_index :samples_workflow_executions, :sample_id
    add_index :workflow_executions, :submitter_id
    add_index :active_storage_attachments, :blob_id
    add_index :active_storage_attachments, :record_id
    add_index :active_storage_variant_records, :blob_id
    add_index :attachments, :attachable_id
    add_index :data_exports, :user_id
    add_index :members, :user_id
    add_index :members, :namespace_id
    add_index :members, :created_by_id
    add_index :namespace_group_links, :group_id
    add_index :namespace_group_links, :namespace_id
    add_index :namespaces, :owner_id
    add_index :namespaces, :parent_id
    add_index :personal_access_tokens, :user_id
    add_index :projects, :creator_id
    add_index :projects, :namespace_id
    add_index :routes, :source_id
    add_index :samples, :project_id

    # Migrate primary keys from UUIDs to IDs
    remove_column :attachments, :id
    remove_column :workflow_executions, :id
    remove_column :samples_workflow_executions, :id
    remove_column :active_storage_attachments, :id
    remove_column :active_storage_blobs, :id
    remove_column :active_storage_variant_records, :id
    remove_column :users, :id
    remove_column :members, :id
    remove_column :namespace_group_links, :id
    remove_column :namespaces, :id
    remove_column :personal_access_tokens, :id
    remove_column :projects, :id
    remove_column :routes, :id
    remove_column :samples, :id

    rename_column :attachments, :uuid, :id
    rename_column :workflow_executions, :uuid, :id
    rename_column :samples_workflow_executions, :uuid, :id
    rename_column :active_storage_attachments, :uuid, :id
    rename_column :active_storage_blobs, :uuid, :id
    rename_column :active_storage_variant_records, :uuid, :id
    rename_column :users, :uuid, :id
    rename_column :members, :uuid, :id
    rename_column :namespace_group_links, :uuid, :id
    rename_column :namespaces, :uuid, :id
    rename_column :personal_access_tokens, :uuid, :id
    rename_column :projects, :uuid, :id
    rename_column :routes, :uuid, :id
    rename_column :samples, :uuid, :id

    execute 'ALTER TABLE attachments ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE workflow_executions ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE samples_workflow_executions ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE active_storage_attachments ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE active_storage_blobs ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE active_storage_variant_records ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE users ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE members ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE namespace_group_links ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE namespaces ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE personal_access_tokens ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE projects ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE routes ADD PRIMARY KEY (id);'
    execute 'ALTER TABLE samples ADD PRIMARY KEY (id);'

    # Add foreign keys
    add_foreign_key :samples_workflow_executions, :workflow_executions
    add_foreign_key :samples_workflow_executions, :samples
    add_foreign_key :workflow_executions, :users, column: :submitter_id
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id
    add_foreign_key :attachments, :samples, column: :attachable_id
    add_foreign_key :data_exports, :users
    add_foreign_key :members, :users
    add_foreign_key :members, :namespaces
    add_foreign_key :namespace_group_links, :namespaces
    add_foreign_key :namespaces, :users, column: :owner_id
    add_foreign_key :personal_access_tokens, :users
    add_foreign_key :projects, :users, column: :creator_id
    add_foreign_key :projects, :namespaces
    add_foreign_key :routes, :namespaces, column: :source_id
    add_foreign_key :samples, :projects

    # Add indexes for ordering by date
    add_index :attachments, :created_at
    add_index :workflow_executions, :created_at
    add_index :samples_workflow_executions, :created_at
    add_index :active_storage_attachments, :created_at
    add_index :active_storage_blobs, :created_at
    add_index :data_exports, :created_at
    add_index :users, :created_at
    add_index :members, :created_at
    add_index :namespace_group_links, :created_at
    add_index :namespaces, :created_at
    add_index :personal_access_tokens, :created_at
    add_index :projects, :created_at
    add_index :routes, :created_at
    add_index :samples, :created_at

    execute <<~SQL.squish
      UPDATE "attachments" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "data_exports" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "users" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "members" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "namespace_group_links" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "namespaces" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at", "metadata_summary"}');
      UPDATE "personal_access_tokens" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at"}');
      UPDATE "samples" as t SET log_data = logidze_snapshot(to_jsonb(t), 'created_at', '{"created_at", "updated_at", "metadata_provenance"}');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
