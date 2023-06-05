# frozen_string_literal: true

# migration to setup logidze
class LogidzeInstall < ActiveRecord::Migration[7.0]
  def change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    reversible do |dir|
      dir.up do
        create_function :logidze_capture_exception, version: 1
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_capture_exception(jsonb) CASCADE'
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_compact_history, version: 1
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_compact_history(jsonb, integer) CASCADE'
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_filter_keys, version: 1
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_filter_keys(jsonb, text[], boolean) CASCADE'
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_logger, version: 3
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_logger() CASCADE'
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_snapshot, version: 3
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_snapshot(jsonb, text, text[], boolean) CASCADE'
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_version, version: 2
      end

      dir.down do
        execute 'DROP FUNCTION IF EXISTS logidze_version(bigint, jsonb, timestamp with time zone) CASCADE'
      end
    end
  end
end
