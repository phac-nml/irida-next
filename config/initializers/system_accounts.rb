# frozen_string_literal: true

# Initializer to provide `system` (metrics) access to users retrieved from credentials
Rails.application.config.after_initialize do
  unless !defined?(Rails::Server) || Rails.application.credentials.system_accounts.nil?
    user_emails = Rails.application.credentials[:system_accounts][:user_emails]

    # Remove users who are no longer given `system` (metrics) access
    existing_system_users = User.where(system: true).where.not(email: user_emails)
    existing_system_users.each do |existing_system_user|
      existing_system_user.update(system: false)
    end

    # Only update users to be given `system` (metrics) access if they have not already been provided access
    users_to_update = User.where(email: user_emails, system: false)
    users_to_update.each do |user_to_update|
      user_to_update.update(system: true)
    end
  end
end
