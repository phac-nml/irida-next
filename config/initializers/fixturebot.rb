# frozen_string_literal: true

# FixtureBot (https://github.com/rubymonolith/fixturebot) is only bundled in the
# `test` group, so this initializer is a no-op outside of the test environment.
if defined?(FixtureBot)
  module FixtureBot
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
        # names unchanged.
        TABLE_PATH_RENAMES = {
          active_storage_attachments: ['active_storage/attachments', :active_storage_attachment],
          activities: ['public_activity/activities', :activity]
        }.freeze

        # `active_storage_attachments.blob_id` points at `active_storage_blobs`, which isn't
        # migrated to FixtureBot (see `test/fixtures/active_storage/blobs.yml`, still plain
        # ERB/YAML), so FixtureBot's key registry never has rows for it. That association must
        # keep being set manually with `ActiveRecord::FixtureSet.identify(:label, :uuid)`
        # instead of the native association DSL, so it's dropped here rather than left to blow
        # up with a `KeyError` if ever called.
        TABLE_PATH_RENAME_DROPPED_ASSOCIATIONS = {
          active_storage_attachments: [:blob]
        }.freeze

        # Some FK columns have no enforced DB-level foreign key (so FixtureBot can't
        # auto-detect an association for them), but this application's models only ever point
        # them at one specific table, so it's safe to wire them up manually and use the native
        # association DSL (e.g. `created_by :john_doe`) instead of a literal UUID.
        # `groups.parent_id` has no enforced DB foreign key either (it points at the
        # pre-split "namespaces" table, which can't have one FK target), but per the same
        # model validations a Group's parent can only ever be another Group (never a project
        # or user namespace), so it's unambiguous and safe to wire up here too - unlike
        # `parent` on the other two split namespace tables, which genuinely can point at
        # either a group or a user namespace and must keep being set manually (see
        # `rename_split_tables` above).
        MANUAL_ASSOCIATIONS = {
          members: [%i[created_by_id created_by users]],
          namespace_bots: [%i[user_id user users]],
          namespace_group_links: [%i[group_id group groups]],
          groups: [%i[parent_id parent groups]]
        }.freeze

        # FK columns whose real DB-level target table ("namespaces") is ambiguous, since it's
        # split into three synthetic tables below, but that - per this application's model-level
        # validations - only ever reference one specific split table in practice, so it's safe
        # to repoint the auto-detected association there and use the native association DSL.
        NAMESPACE_ASSOCIATION_OVERRIDES = {
          projects: { namespace_id: :'namespaces/project_namespaces' },
          automated_workflow_executions: { namespace_id: :'namespaces/project_namespaces' }
        }.freeze

        alias build_schema_without_namespace_split build_schema
        private :build_schema_without_namespace_split

        def build_schema
          schema = build_schema_without_namespace_split
          rename_split_tables(schema)
          rename_path_tables(schema)
          add_manual_associations(schema)
          repoint_namespace_associations(schema)
          schema
        end

        private

        def rename_split_tables(schema)
          namespaces_table = schema.tables.delete(:namespaces)
          return unless namespaces_table

          # The `owner` association (always a `User`, never a `Namespace`) survives the split
          # unambiguously and is kept as-is; `parent` has no enforced DB foreign key (so no
          # association was auto-detected for it in the first place). It's wired up manually
          # for the `groups` table below (see `MANUAL_ASSOCIATIONS`), since a group's parent
          # can only ever be another group, but must keep being set via a raw UUID lookup for
          # the other two split tables, since their parent can be either a group or a user
          # namespace.
          NAMESPACE_SPLIT_TABLES.each do |name, singular_name|
            schema.add_table(namespaces_table.with(name: name, singular_name: singular_name))
          end
        end

        def rename_path_tables(schema)
          renames = {}
          TABLE_PATH_RENAMES.each do |original_name, (new_name, singular_name)|
            table = schema.tables.delete(original_name)
            next unless table

            dropped = TABLE_PATH_RENAME_DROPPED_ASSOCIATIONS[original_name] || []
            associations = table.associations.reject { |a| dropped.include?(a.name) }
            schema.add_table(table.with(name: new_name.to_sym, singular_name: singular_name,
                                        associations: associations))
            renames[original_name] = new_name.to_sym
          end
          remap_renamed_table_references(schema, renames) if renames.any?
        end

        # Other tables' associations that point at a renamed table (e.g.
        # `activity_extended_details.activity_id -> activities`) need their `table:` updated to
        # match the new name, or FixtureBot's key registry won't find the referenced rows.
        def remap_renamed_table_references(schema, renames)
          schema.tables.each do |table_name, table|
            next if table.associations.none? { |a| renamed_association?(a, renames) }

            associations = table.associations.map { |a| remap_association(a, renames) }
            schema.tables[table_name] = table.with(associations: associations)
          end
        end

        def renamed_association?(association, renames)
          association.respond_to?(:table) && renames.key?(association.table)
        end

        def remap_association(association, renames)
          return association unless renamed_association?(association, renames)

          association.with(table: renames[association.table])
        end

        def add_manual_associations(schema)
          MANUAL_ASSOCIATIONS.each do |table_name, specs|
            table = schema.tables[table_name]
            next unless table

            new_associations = specs.map do |column, name, target_table|
              Schema::BelongsTo.new(name: name, table: target_table, foreign_key: column)
            end
            schema.tables[table_name] = table.with(associations: table.associations + new_associations)
          end
        end

        def repoint_namespace_associations(schema)
          NAMESPACE_ASSOCIATION_OVERRIDES.each do |table_name, columns|
            table = schema.tables[table_name]
            next unless table

            associations = table.associations.map do |assoc|
              target_table = columns[assoc.foreign_key]
              target_table ? assoc.with(table: target_table) : assoc
            end
            schema.tables[table_name] = table.with(associations: associations)
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
      # Raised in CI when a compiled fixture YAML file would change, meaning the
      # committed file no longer matches its FixtureBot `.rb` source (e.g. it was
      # hand-edited, or the `.rb` source changed without recompiling/committing the
      # regenerated YAML).
      class StaleFixturesError < StandardError
        def initialize(paths)
          super(<<~MESSAGE)
            The following compiled fixture files don't match their FixtureBot `.rb` source:
            #{paths.map { |path| "  #{path}" }.join("\n")}

            All fixture changes must be made in the `.rb` files under `test/fixtures/`, not
            by hand-editing the compiled YAML. Run `bin/rails fixturebot:compile` (or the
            test suite, which recompiles automatically) and commit the regenerated YAML.
          MESSAGE
        end
      end

      def compile(output_dir)
        FileUtils.mkdir_p(output_dir)
        stale_paths = []

        @fixture_set.tables.each do |table_name, records|
          next if records.empty?

          path = File.join(output_dir, "#{table_name}.yml")
          compiled = compile_table(table_name)

          if ENV['CI'] == 'true' && File.exist?(path) && File.read(path) != compiled
            stale_paths << path
            next
          end

          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, compiled)
        end

        raise StaleFixturesError, stale_paths if stale_paths.any?
      end
    end
  end
end
