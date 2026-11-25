# frozen_string_literal: true

# FixtureBot (https://github.com/rubymonolith/fixturebot) is only bundled in the
# `test` group, so this initializer is a no-op outside of the test environment.
if defined?(FixtureBot)
  module FixtureBot
    module Key
      # Overridden so IDs generated for FixtureBot-defined records are identical to the
      # ones Rails' own `ActiveRecord::FixtureSet.identify` would assign. This keeps
      # fixture files that have been migrated to FixtureBot interoperable with ones that
      # haven't been migrated yet (and vice versa), since both resolve the same label to
      # the same UUID, allowing fixtures to be migrated to FixtureBot incrementally.
      module Uuid
        def self.generate(_table_name, record_name)
          ActiveRecord::FixtureSet.identify(record_name, :uuid)
        end
      end
    end

    module Rails
      # Reopened to override #timestamp_column? and #build_schema below.
      class SchemaLoader
        # `groups.yml`, `namespaces/project_namespaces.yml` and `namespaces/user_namespaces.yml`
        # are three separate Rails fixture files/accessors (`groups(:x)`,
        # `namespaces_project_namespaces(:x)`, `namespaces_user_namespaces(:x)`) that all map
        # to the single STI `namespaces` database table. FixtureBot only generates one DSL
        # method/compiled file per database table, so the real `namespaces` table is split
        # here into three synthetic FixtureBot tables - one per original fixture file - keeping
        # the existing accessors/file layout unchanged and avoiding a mass call-site rename.
        NAMESPACE_SPLIT_TABLES = {
          groups: :group,
          'namespaces/project_namespaces': :namespaces_project_namespace,
          'namespaces/user_namespaces': :namespaces_user_namespace
        }.freeze

        # Some tables' original fixture files live in a subdirectory purely for
        # organization/namespacing (e.g. `active_storage/attachments.yml` for the
        # `active_storage_attachments` table, matching the `ActiveStorage::Attachment`
        # model namespace; `public_activity/activities.yml` for the `activities` table).
        # FixtureBot's compiled output path always mirrors the table name, so these
        # tables are renamed here to keep the original nested file layout/accessor
        # names unchanged. Associations are dropped for the same reason as the
        # namespaces split above: any FK must be set with a literal
        # `ActiveRecord::FixtureSet.identify(:label, :uuid)` call instead of FixtureBot's
        # association shorthand, since the renamed table name no longer matches what the
        # association metadata resolves against.
        TABLE_PATH_RENAMES = {
          active_storage_attachments: ['active_storage/attachments', :active_storage_attachment],
          activities: ['public_activity/activities', :activity]
        }.freeze

        alias build_schema_without_namespace_split build_schema
        private :build_schema_without_namespace_split

        def build_schema
          schema = build_schema_without_namespace_split
          rename_split_tables(schema)
          rename_path_tables(schema)
          schema
        end

        private

        def rename_split_tables(schema)
          namespaces_table = schema.tables.delete(:namespaces)
          return unless namespaces_table

          # Associations are dropped: any foreign key pointing at `namespaces` (e.g.
          # `owner_id`, `parent_id`) must be set with a literal
          # `ActiveRecord::FixtureSet.identify(:label, :uuid)` call instead of FixtureBot's
          # association shorthand, since the split tables no longer match the real table
          # name the association metadata resolves against.
          NAMESPACE_SPLIT_TABLES.each do |name, singular_name|
            schema.add_table(namespaces_table.with(name: name, singular_name: singular_name, associations: []))
          end
        end

        def rename_path_tables(schema)
          TABLE_PATH_RENAMES.each do |original_name, (new_name, singular_name)|
            table = schema.tables.delete(original_name)
            next unless table

            schema.add_table(table.with(name: new_name.to_sym, singular_name: singular_name, associations: []))
          end
        end

        # By default FixtureBot drops `created_at`/`updated_at` from the generated schema,
        # so they can't be set from the DSL. Many of our fixtures rely on explicit,
        # relative timestamps (e.g. `3.hours.ago`), so keep these columns available.
        def timestamp_column?(_name) = false
      end
    end

    # Reopened so FixtureBot can write a compiled file to a nested directory (e.g.
    # `namespaces/project_namespaces.yml`), matching the original fixture file layout.
    class Compiler
      def compile(output_dir)
        FileUtils.mkdir_p(output_dir)
        @fixture_set.tables.each do |table_name, records|
          next if records.empty?

          path = File.join(output_dir, "#{table_name}.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, compile_table(table_name))
        end
      end
    end
  end
end
