# frozen_string_literal: true

require 'test_helper'

module Bots
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @group = groups(:group_one)
      @project = projects(:project1)
      @project_bot_type = User.user_types[:project_bot]
      @project_automation_bot_type = User.user_types[:project_automation_bot]
      @group_bot_type = User.user_types[:group_bot]
    end

    test 'create new project bot account' do
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      assert_difference -> { User.count } => 1, -> { PersonalAccessToken.count } => 1, -> { Member.count } => 1 do
        Bots::CreateService.new(@user, @project.namespace, @project_bot_type, valid_params).execute
      end
    end

    test 'project bot account not created due to missing token name' do
      invalid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { scopes: %w[read_api api] }
          ]
        }
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, @project_bot_type, invalid_params).execute

        assert result.user.personal_access_tokens[0].errors.added?(:name, :blank)
      end
    end

    test 'project bot account not created as token scopes are missing' do
      invalid_params =
        {
          user_attributes: {
            members_attributes: {
              '0': { access_level: Member::AccessLevel::UPLOADER }
            },
            personal_access_tokens_attributes: [
              { name: 'newtoken' }
            ]
          }
        }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, @project_bot_type, invalid_params).execute

        assert result.user.personal_access_tokens[0].errors.added?(:scopes, :blank)
      end
    end

    test 'project bot account not created due to missing access level' do
      invalid_params = {
        user_attributes: {
          personal_access_tokens_attributes: [
            { name: 'newtoken', scopes: %w[read_api api] }
          ]
        }
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @project.namespace, @project_bot_type, invalid_params).execute

        assert result.user.members[0].errors.added?(:access_level, :blank)
      end
    end

    test 'valid authorization to create project bot account' do
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      assert_authorized_to(:create_bot_accounts?, @project.namespace,
                           with: Namespaces::ProjectNamespacePolicy,
                           context: { user: @user }) do
        Bots::CreateService.new(@user, @project.namespace, @project_bot_type, valid_params).execute
      end
    end

    test 'invalid authorization to create project bot account' do
      user = users(:micha_doe)
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::CreateService.new(user, @project.namespace, @project_bot_type, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :create_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.create_bot_accounts?',
                          name: @project.name),
                   exception.result.message
    end

    test 'create new group bot account' do
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      assert_difference -> { User.count } => 1, -> { PersonalAccessToken.count } => 1, -> { Member.count } => 1 do
        Bots::CreateService.new(@user, @group, @group_bot_type, valid_params).execute
      end
    end

    test 'group bot account not created due to missing token name' do
      invalid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { scopes: %w[read_api api] }
          ]
        }
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @group, @group_bot_type, invalid_params).execute

        assert result.user.personal_access_tokens[0].errors.added?(:name, :blank)
      end
    end

    test 'group bot account not created as token scopes are missing' do
      invalid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'newtoken' }
          ]
        }
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @group, @group_bot_type, invalid_params).execute

        assert result.user.personal_access_tokens[0].errors.added?(:scopes, :blank)
      end
    end

    test 'group bot account not created due to missing access level' do
      invalid_params = {
        user_attributes: {
          personal_access_tokens_attributes: [
            { name: 'newtoken', scopes: %w[read_api api] }
          ]
        }
      }

      assert_no_difference ['User.count', 'PersonalAccessToken.count', 'Member.count'] do
        result = Bots::CreateService.new(@user, @group, @group_bot_type, invalid_params).execute

        assert result.user.members[0].errors.added?(:access_level, :blank)
      end
    end

    test 'valid authorization to create group bot account' do
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      assert_authorized_to(:create_bot_accounts?, @group,
                           with: GroupPolicy,
                           context: { user: @user }) do
        Bots::CreateService.new(@user, @group, @group_bot_type, valid_params).execute
      end
    end

    test 'invalid authorization to create group bot account' do
      user = users(:micha_doe)
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          },
          personal_access_tokens_attributes: [
            { name: 'Uploader', scopes: %w[read_api api] }
          ]
        }
      }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Bots::CreateService.new(user, @group, @group_bot_type, valid_params).execute
      end

      assert_equal GroupPolicy, exception.policy
      assert_equal :create_bot_accounts?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.group.create_bot_accounts?',
                          name: @group.name),
                   exception.result.message
    end

    test 'project automation bot should not have any personal access tokens' do
      valid_params = {
        user_attributes: {
          members_attributes: {
            '0': { access_level: Member::AccessLevel::UPLOADER }
          }
        }
      }

      assert_difference -> { User.count } => 1, -> { PersonalAccessToken.count } => 0, -> { Member.count } => 1 do
        Bots::CreateService.new(@user, @project.namespace, @project_automation_bot_type, valid_params).execute
      end
    end
  end
end
