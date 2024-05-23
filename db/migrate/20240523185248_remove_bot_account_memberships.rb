# frozen_string_literal: true

# migration to remove existing bot users and their memberships that were left behind when a bot account was removed
class RemoveBotAccountMemberships < ActiveRecord::Migration[7.1]
  def change
    deleted_bot_ids = NamespaceBot.only_deleted.select(:user_id)
    User.where(id: deleted_bot_ids).find_each(&:destroy)
  end
end
