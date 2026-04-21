# frozen_string_literal: true

namespace :personal_access_tokens do
  desc 'destroys expired and revoked personal access tokens'
  task cleanup: [:environment] do |_t, _args|
    puts 'Running personal access tokens cleanup job for expired and revoked tokens.'
    PersonalAccessTokens::CleanupJob.perform_now
  end
end
