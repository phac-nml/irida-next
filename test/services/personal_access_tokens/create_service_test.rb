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
