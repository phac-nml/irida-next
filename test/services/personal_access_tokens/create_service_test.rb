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
        token = PersonalAccessTokens::CreateService.new(
          @user, valid_params, @project.namespace, namespace_bot.user
        ).execute

        assert_predicate token, :persisted?
        assert_equal namespace_bot.user, token.user
        assert_equal valid_params[:name], token.name
        assert_equal valid_params[:scopes], token.scopes
      end
    end

    test 'authorizes project namespace when creating a bot token' do
      valid_params = { name: 'Uploader', scopes: %w[read_api api] }

      assert_authorized_to(:generate_bot_personal_access_token?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        PersonalAccessTokens::CreateService.new(
          @user, valid_params, @project.namespace, namespace_bots(:project1_bot0).user
        ).execute
      end
    end

    test 'does not create a bot token without namespace authorization' do
      user = users(:micha_doe)
      valid_params = { name: 'Uploader', scopes: %w[read_api api] }

      exception = nil
      assert_no_difference -> { PersonalAccessToken.count } do
        exception = assert_raises(ActionPolicy::Unauthorized) do
          PersonalAccessTokens::CreateService.new(
            user, valid_params, @project.namespace, namespace_bots(:project1_bot0).user
          ).execute
        end
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :generate_bot_personal_access_token?, exception.rule
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
      expires_at = Time.zone.today + Irida::CurrentSettings.max_personal_access_token_lifetime_in_days

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
        token = PersonalAccessTokens::CreateService.new(@user, valid_params).execute

        assert_predicate token, :persisted?
        assert_equal @user, token.user
        assert_equal valid_params[:name], token.name
        assert_equal valid_params[:scopes], token.scopes
      end
    end

    test 'authorizes the current user when creating a user token' do
      valid_params = { name: 'Uploader', scopes: %w[read_api api] }

      assert_authorized_to(:generate_bot_personal_access_token?, @user,
                           with: UserPolicy,
                           context: { user: @user }) do
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
      expires_at = Time.zone.today + Irida::CurrentSettings.max_personal_access_token_lifetime_in_days.days

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
