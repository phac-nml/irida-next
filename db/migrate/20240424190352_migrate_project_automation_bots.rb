# frozen_string_literal: true

# migration to add project automation bots to existing projects and
# remove existing namespace_bot records for project automation bots
class MigrateProjectAutomationBots < ActiveRecord::Migration[7.1]
  def up # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    bot_type = User.user_types[:project_automation_bot]

    execute <<-SQL.squish
      DELETE FROM namespace_bots WHERE user_id IN (SELECT id FROM users WHERE user_type='#{bot_type}');
    SQL

    Namespaces::ProjectNamespace.find_each do |proj_namespace|
      next unless proj_namespace.users.find_by(user_type: bot_type).nil?

      puid = proj_namespace.puid
      email = "#{puid.downcase}_automation_bot@iridanext.com"
      access_level = Member::AccessLevel::MAINTAINER
      first_name = puid
      last_name = 'Automation Bot'

      execute <<-SQL.squish
        INSERT INTO users (email, first_name, last_name, user_type, created_at, updated_at) VALUES ('#{email}','#{first_name}','#{last_name}','#{bot_type}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      SQL

      user = User.find_by(email:)

      execute <<-SQL.squish
        INSERT INTO members (namespace_id, user_id, access_level, created_by_id, created_at, updated_at) VALUES ('#{proj_namespace.id}', '#{user.id}', '#{access_level}', '#{proj_namespace.project.creator_id}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
