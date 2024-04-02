# frozen_string_literal: true

require 'test_helper'

module Bots
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'create new bot account' do
      valid_params = {
        token_name: 'Uploader',
        scopes: %w[read_api api],
        access_level: Member::AccessLevel::UPLOADER
      }

      assert_difference -> { User.count } => 1, -> { PersonalAccessToken.count } => 1, -> { Member.count } => 1 do
        Bots::CreateService.new(@user, @project.namespace, valid_params).execute
      end
    end

    test 'bot account not created due to missing token name' do
      invalid_params = {
        scopes: %w[read_api api],
        access_level: Member::AccessLevel::UPLOADER
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, invalid_params).execute

        assert result[:bot_user_account].errors.full_messages.include?('Unable to create bot account as the token name is required')
      end
    end

    test 'bot account not created as token scopes are missing' do
      invalid_params = {
        token_name: 'newtoken',
        access_level: Member::AccessLevel::UPLOADER
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, invalid_params).execute

        assert result[:bot_user_account].errors.full_messages.include?('Unable to create bot account as the bot API scope must be selected')
      end
    end

    test 'bot account not created due to missing access level' do
      invalid_params = {
        token_name: 'newtoken',
        scopes: %w[read_api api]
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, invalid_params).execute

        assert result[:bot_user_account].errors.full_messages.include?('Unable to create bot account as an access level must be selected')
      end
    end

    test 'valid authorization to create bot account' do
      valid_params = {
        token_name: 'Uploader',
        scopes: %w[read_api api],
        access_level: Member::AccessLevel::UPLOADER
      }

      assert_authorized_to(:create_bot_accounts?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Bots::CreateService.new(@user, @project.namespace, valid_params).execute
      end
    end

    test 'invalid authorization to create bot account' do
      user = users(:micha_doe)
      valid_params = {
        token_name: 'Uploader',
        scopes: %w[read_api api],
        access_level: Member::AccessLevel::UPLOADER
      }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::CreateService.new(user, @project.namespace, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :create_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.create_bot_accounts?', name: @project.name),
                   exception.result.message
    end
  end
end
