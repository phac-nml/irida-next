# frozen_string_literal: true

require 'test_helper'

module PersonalAccessTokens
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'create new personal access token for bot account' do
      valid_params = {
        name: 'Uploader',
        scopes: %w[read_api api]
      }

      namespace_bot = namespace_bots(:project1_bot0)

      assert_difference -> { PersonalAccessToken.count } => 1 do
        PersonalAccessTokens::CreateService.new(@user, valid_params, @project.namespace, namespace_bot.user).execute
      end
    end

    test 'create new personal access token for bot account with missing token name' do
      valid_params = {
        scopes: %w[read_api api]
      }

      namespace_bot = namespace_bots(:project1_bot0)

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, valid_params, @project.namespace, namespace_bot.user).execute
      end
    end

    test 'create new personal access token for bot account with missing mandatory expiration date' do
      Irida::CurrentSettings.current_application_settings.update(require_personal_access_token_expiry: true)

      invalid_params = {
        scopes: %w[read_api api]
      }

      namespace_bot = namespace_bots(:project1_bot0)

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, invalid_params, @project.namespace, namespace_bot.user).execute
      end
    end

    test 'create new personal access token for bot account with expiration date past max allowable date' do
      Irida::CurrentSettings.current_application_settings.update(require_personal_access_token_expiry: true)

      # default is 365 days, so we add 1 to get outside the max allowed date
      expires_at = (Time.zone.today + Irida::CurrentSettings.max_personal_access_token_lifetime_in_days).to_s

      invalid_params = {
        scopes: %w[read_api api],
        expires_at: expires_at
      }
      namespace_bot = namespace_bots(:project1_bot0)

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, invalid_params, @project.namespace, namespace_bot.user).execute
      end
    end

    test 'create new personal access token for bot account with missing scopes' do
      valid_params = {
        name: 'Uploader'
      }

      namespace_bot = namespace_bots(:project1_bot0)

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, valid_params, @project.namespace, namespace_bot.user).execute
      end
    end

    test 'create new personal access token for user' do
      valid_params = {
        name: 'Uploader',
        scopes: %w[read_api api]
      }

      assert_difference -> { PersonalAccessToken.count } => 1 do
        PersonalAccessTokens::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create new personal access token for user with missing token name' do
      valid_params = {
        scopes: %w[read_api api]
      }

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create new personal access token for user with missing mandatory expiration date' do
      Irida::CurrentSettings.current_application_settings.update(require_personal_access_token_expiry: true)

      invalid_params = {
        scopes: %w[read_api api]
      }

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create new personal access token for user with expiration date past max allowable date' do
      Irida::CurrentSettings.current_application_settings.update(require_personal_access_token_expiry: true)

      # default is 365 days, so we add 1 to get outside the max allowed date
      expires_at = (Time.zone.today + Irida::CurrentSettings.max_personal_access_token_lifetime_in_days.days).to_s

      invalid_params = {
        scopes: %w[read_api api],
        expires_at: expires_at
      }

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create new personal access token for user with missing scopes' do
      valid_params = {
        name: 'Uploader'
      }

      assert_difference -> { PersonalAccessToken.count } => 0 do
        PersonalAccessTokens::CreateService.new(@user, valid_params).execute
      end
    end
  end
end
