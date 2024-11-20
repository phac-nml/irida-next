# frozen_string_literal: true

# Migration to move Azure AD users to Entra ID
class AzureAdToEntraId < ActiveRecord::Migration[7.2]
  def up
    azure_user_list = User.where(provider: 'azure_activedirectory_v2').all

    # If there are no AD users in the database, exit early.
    if azure_user_list.count.positive?
      Rails.logger.info 'No Azure AD users in database. No Migration needed.'
      return
    end

    tenant_id = find_tenant_id

    azure_user_list.each { |u| migrate_user(u, tenant_id) }
  end

  # Tries to get tenant_id from the entra_id credentials. Raises an error to abort the migration if it cannot be found.
  def find_tenant_id
    begin
      tenant_id = Rails.application.credentials.entra_id[:tenant_id]
    rescue NoMethodError
      error_msg = 'Could not find credentials for Entra ID'
      Rails.logger.error error_msg
      raise StandardError error_msg
    end

    unless tenant_id
      error_msg = 'tenant_id for entra_id is not specified'
      Rails.logger.error error_msg
      raise StandardError error_msg
    end

    tenant_id
  end

  def migrate_user(user, tenant_id)
    old_uid = user.uid
    new_uid = tenant_id + old_uid
    user.uid = new_uid
    user.provider = 'entra_id'
    user.save!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
