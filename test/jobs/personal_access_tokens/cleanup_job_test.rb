# frozen_string_literal: true

require 'test_helper'
module PersonalAccessTokens
  class CleanupJobTest < ActiveJob::TestCase
    def setup
      @personal_access_token = personal_access_tokens(:john_doe_valid_pat)
      @current_date = Time.zone.now
      @cleanup_inactive_access_tokens_after_days = Irida::CurrentSettings.current_application_settings.cleanup_inactive_access_tokens_after_days
    end

    test 'cleanup user personal access tokens that are inactive for more than the specified number of days' do
      assert @personal_access_token.valid?

      @personal_access_token.update!(revoked: true,
                                     updated_at: @current_date - (@cleanup_inactive_access_tokens_after_days + 1).days)

      assert_difference -> { PersonalAccessToken.where(id: @personal_access_token.id).count }, -1 do
        PersonalAccessTokens::CleanupJob.perform_now
      end

      assert_raises(ActiveRecord::RecordNotFound) { @personal_access_token.reload }
    end

    test 'cleanup personal access tokens fixtures that are inactive for more than the specified number of days' do
      # Destroys fixtures expired and revoked tokens > cleanup_inactive_access_tokens_after_days
      assert_difference -> { PersonalAccessToken.count } => -3 do
        PersonalAccessTokens::CleanupJob.perform_now
      end
    end

    test 'does not cleanup expired tokens that are not yet past the cutoff date' do
      token = PersonalAccessToken.create!(
        user: users(:john_doe),
        name: 'Expired but young PAT',
        scopes: ['api']
      )

      token.update!(expires_at: (@current_date - 10.days).to_date)

      assert_no_difference -> { PersonalAccessToken.where(id: token.id).count } do
        PersonalAccessTokens::CleanupJob.perform_now
      end

      assert_equal token.id, PersonalAccessToken.find(token.id).id
    end

    test 'does not cleanup revoked tokens that are not yet past the cutoff date' do
      token = PersonalAccessToken.create!(
        user: users(:john_doe),
        name: 'Expired but young PAT',
        scopes: ['api'],
        revoked: true,
        updated_at: @current_date
      )

      assert_no_difference -> { PersonalAccessToken.where(id: token.id).count } do
        PersonalAccessTokens::CleanupJob.perform_now
      end

      assert_equal token.id, PersonalAccessToken.find(token.id).id
    end
  end
end
