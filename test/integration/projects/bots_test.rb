# frozen_string_literal: true

require 'test_helper'

module Projects
  class BotsTest < ActionDispatch::IntegrationTest
    test 'can view bot listings for a project with proper access' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select 'h1', I18n.t('projects.bots.index.title')
      assert_select 'p', I18n.t('projects.bots.index.subtitle')
      assert_select 'button', text: I18n.t('projects.bots.index.add_new_bot')

      assert_select 'table' do
        assert_select 'tbody' do
          assert_select 'tr', count: Pagy::OPTIONS[:limit]
        end
      end

      assert_select %(a[aria-label="#{I18n.t('components.viral.pagy.pagination_component.next_aria_label')}"]),
                    text: I18n.t('components.viral.pagy.pagination_component.next')
    end

    test 'cannot view bot listings for a project without proper access' do
      sign_in users(:ryan_doe)
      namespace = groups(:group_one)
      project = projects(:project1)

      get namespace_project_bots_path(namespace, project)
      assert_response :unauthorized

      assert_select 'h1', I18n.t('application.errors.access_denied')
    end

    test 'can see empty state when project has no bots' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project2)

      get namespace_project_bots_path(namespace, project)

      assert_response :success

      assert_select 'h1', I18n.t('projects.bots.index.title')
      assert_select 'div.empty_state_message'

      assert_select 'table', count: 0
    end

    test 'can create a new project bot account' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project2)

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select 'button', text: I18n.t('projects.bots.index.add_new_bot')

      get new_namespace_project_bot_path(namespace, project), as: :turbo_stream
      assert_response :success

      assert_select 'h1', I18n.t('projects.bots.index.bot_listing.new_bot_modal.title')

      assert_difference -> { project.namespace.bots.count } do
        post namespace_project_bots_path(namespace, project),
             params: { namespace_bot: { user_attributes: {
               members_attributes: {
                 '0': { access_level: Member::AccessLevel::ANALYST }
               },
               personal_access_tokens_attributes: {
                 '0': {
                   name: 'Uploader',
                   scopes: %w[read_api api]
                 }
               }
             } } }, as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t('concerns.bot_actions.create.success')}"
          end
        end
      end
    end

    test 'can create a new project bot account and switching locale removes access token section' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project2)

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select 'h1', I18n.t('projects.bots.index.title')

      assert_difference -> { project.namespace.bots.count } do
        post namespace_project_bots_path(namespace, project),
             params: { namespace_bot: { user_attributes: {
               members_attributes: {
                 '0': { access_level: Member::AccessLevel::ANALYST }
               },
               personal_access_tokens_attributes: {
                 '0': {
                   name: 'Uploader',
                   scopes: %w[read_api api]
                 }
               }
             } } }, as: :turbo_stream
      end

      assert_response :success

      assert_select '#access-token-section > div', count: 1

      # switch locale and verify access token section is removed
      I18n.with_locale(:fr) do
        get namespace_project_bots_path(namespace, project, locale: :fr)
        assert_response :success

        assert_select '#access-token-section > div', count: 0
      end
    end

    test 'cannot create project bot account without required values' do
      sign_in users(:john_doe)
      namespace = groups(:group_one)
      project = projects(:project2)

      get new_namespace_project_bot_path(namespace, project), as: :turbo_stream
      assert_response :success

      assert_select 'h1', I18n.t('projects.bots.index.bot_listing.new_bot_modal.title')

      assert_no_difference -> { project.namespace.bots.count } do
        post namespace_project_bots_path(namespace, project),
             params: { namespace_bot: { user_attributes: {
               members_attributes: {
                 '0': { access_level: Member::AccessLevel::ANALYST }
               },
               personal_access_tokens_attributes: {
                 '0': {
                   name: 'testtoken',
                   scopes: []
                 }
               }
             } } }, as: :turbo_stream
      end

      assert_response :unprocessable_entity

      I18n.t(:'errors.format',
             attribute: PersonalAccessToken.human_attribute_name(:scopes),
             message: I18n.t(:'errors.messages.blank'))

      assert_no_difference -> { project.namespace.bots.count } do
        post namespace_project_bots_path(namespace, project),
             params: { namespace_bot: { user_attributes: {
               members_attributes: {
                 '0': { access_level: Member::AccessLevel::ANALYST }
               },
               personal_access_tokens_attributes: {
                 '0': {
                   name: '',
                   scopes: ['read_api']
                 }
               }
             } } }, as: :turbo_stream

        assert_response :unprocessable_entity

        I18n.t(:'errors.format',
               attribute: PersonalAccessToken.human_attribute_name(:name),
               message: I18n.t(:'errors.messages.blank'))

        # Mandatory expiry date for personal access tokens
        ApplicationSetting.current.update(require_personal_access_token_expiry: true)

        assert_no_difference -> { project.namespace.bots.count } do
          post namespace_project_bots_path(namespace, project),
               params: { namespace_bot: { user_attributes: {
                 members_attributes: {
                   '0': { access_level: Member::AccessLevel::ANALYST }
                 },
                 personal_access_tokens_attributes: {
                   '0': {
                     name: 'newesttesttoken',
                     scopes: ['read_api'],
                     expires_at: ''
                   }
                 }
               } } }, as: :turbo_stream

          assert_response :unprocessable_entity

          I18n.t(:'errors.format',
                 attribute: PersonalAccessToken.human_attribute_name(:expires_at),
                 message: I18n.t(:'errors.messages.blank'))
        end
      end
    end

    test 'can delete a project bot account' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      assert_difference -> { project.namespace.bots.count }, -1 do
        delete namespace_project_bot_path(namespace, project, bot),
               as: :turbo_stream
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t('concerns.bot_actions.destroy.success')}"
      end
    end

    test 'cannot delete a project bot account when deletion fails' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      # Mock the destroy service to return a bot that wasn't deleted
      destroy_service_mock = mock('destroy_service')
      destroy_service_mock.expects(:execute).once

      ::Bots::DestroyService.expects(:new).with(bot, users(:john_doe)).returns(destroy_service_mock)

      # Simulate deletion failure by making the bot not deleted
      def bot.deleted?
        false
      end

      assert_no_difference -> { project.namespace.bots.count } do
        delete namespace_project_bot_path(namespace, project, bot),
               as: :turbo_stream
      end

      assert_response :unprocessable_entity
    end

    test 'can view personal access tokens for bot account' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      get namespace_project_bot_personal_access_tokens_path(namespace, project, bot), as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t('projects.bots.index.personal_access_tokens_listing_modal.title')
      assert_select 'p',
                    text: I18n.t('projects.bots.index.personal_access_tokens_listing_modal.description.active',
                                 bot_account: bot.user.email)

      assert_select 'table' do
        assert_select 'thead' do
          assert_select 'th', text: I18n.t('personal_access_tokens.table.header.action'),
                              count: bot.user.personal_access_tokens.active.count
        end
        assert_select 'tbody' do
          assert_select 'tr', count: bot.user.personal_access_tokens.active.count do
            assert_select 'td > button > span', text: I18n.t('personal_access_tokens.table.revoke'),
                                                count: bot.user.personal_access_tokens.active.count
          end
        end
      end

      get inactive_namespace_project_bot_personal_access_tokens_path(namespace, project, bot), as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t('projects.bots.index.personal_access_tokens_listing_modal.title')
      assert_select 'p', text: I18n.t('projects.bots.index.personal_access_tokens_listing_modal.description.inactive',
                                      bot_account: bot.user.email)

      assert_select 'table' do
        assert_select 'thead' do
          assert_select 'th', text: I18n.t('personal_access_tokens.table.header.action'), count: 0
        end
        assert_select 'tbody' do
          assert_select 'tr', count: bot.user.personal_access_tokens.inactive.count do
            assert_select 'td > button > span', text: I18n.t('personal_access_tokens.table.revoke'), count: 0
            assert_select 'td > button > span', text: I18n.t('personal_access_tokens.table.rotate'), count: 0
          end
        end
      end
    end

    test 'can generate a new personal access token for bot account' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select '#access-token-section > div', count: 0

      get new_namespace_project_bot_personal_access_token_path(namespace, project, bot), as: :turbo_stream
      assert_response :success

      assert_select 'h1', text: I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.title')

      assert_difference -> { bot.user.personal_access_tokens.count } do
        post namespace_project_bot_personal_access_tokens_path(namespace, project, bot),
             params: { personal_access_token: {
               name: 'Test Token',
               scopes: ['read_api']
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select '#access-token-section > div', count: 1
    end

    test 'cannot generate a new personal access token when creation fails' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      # Mock the CreateService to return a token with errors
      create_service_mock = mock('create_service')
      # Create a real token object with errors instead of mocking everything
      token_with_errors = PersonalAccessToken.new
      token_with_errors.errors.add(:base, 'Creation failed')

      create_service_mock.stubs(:execute).returns(token_with_errors)

      PersonalAccessTokens::CreateService.expects(:new).returns(create_service_mock)
      assert_no_difference -> { bot.user.personal_access_tokens.count } do
        post namespace_project_bot_personal_access_tokens_path(namespace, project, bot),
             params: { personal_access_token: {
               name: 'Test Token',
               scopes: ['read_api']
             } },
             as: :turbo_stream
      end

      assert_response :unprocessable_entity
    end

    test 'can rotate a personal access token' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project
      token = bot.user.personal_access_tokens.active.first

      initial_active_token_count = bot.user.personal_access_tokens.active.count
      initial_inactive_token_count = bot.user.personal_access_tokens.inactive.count

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select 'h1', text: I18n.t('projects.bots.index.title')
      assert_select 'td > button > span', text: initial_active_token_count.to_s
      assert_select 'td > button > span', text: initial_inactive_token_count.to_s
      assert_select '#access-token-section > div', count: 0

      get namespace_project_bot_personal_access_tokens_path(namespace, project, bot), as: :turbo_stream
      assert_response :success

      assert_difference -> { bot.user.personal_access_tokens.inactive.count }, 1 do
        assert_no_difference -> { bot.user.personal_access_tokens.active.count } do
          put rotate_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
              as: :turbo_stream
        end
      end

      assert_response :success

      assert_select 'div',
                    text: I18n.t('concerns.bot_personal_access_token_actions.rotate.success', pat_name: token.name)
      assert_select '#access-token-section > div', count: 1
      assert_select 'td > button > span', text: I18n.t('personal_access_tokens.table.revoke'),
                                          count: initial_active_token_count
    end

    test 'can view rotate confirmation for project bot personal access token' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project
      token = bot.user.personal_access_tokens.active.first

      get rotate_confirmation_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
          as: :turbo_stream
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="token_dialog"]' do
        assert_select 'template' do
          assert_select 'dialog'
        end
      end
    end

    test 'cannot rotate a personal access token when rotation fails' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project
      token = bot.user.personal_access_tokens.active.first

      # Mock the RotateService to return a token with errors
      rotate_service_mock = mock('rotate_service')
      # Create a real token object with errors
      rotated_token = PersonalAccessToken.new
      rotated_token.errors.add(:base, 'Rotation failed')
      rotate_service_mock.stubs(:execute).returns(rotated_token)

      PersonalAccessTokens::RotateService.expects(:new).returns(rotate_service_mock)

      bot.user.personal_access_tokens.active.count
      bot.user.personal_access_tokens.inactive.count

      assert_no_difference -> { bot.user.personal_access_tokens.inactive.count } do
        assert_no_difference -> { bot.user.personal_access_tokens.active.count } do
          put rotate_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
              as: :turbo_stream
        end
      end

      assert_response :unprocessable_entity
    end

    test 'can revoke a personal access token' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project
      token = bot.user.personal_access_tokens.active.first

      get namespace_project_bots_path(namespace, project)
      assert_response :success

      assert_select 'h1', text: I18n.t('projects.bots.index.title')

      get namespace_project_bot_personal_access_tokens_path(namespace, project, bot), as: :turbo_stream
      assert_response :success

      delete revoke_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
             as: :turbo_stream

      assert_response :success

      assert_select 'div',
                    text: I18n.t('concerns.bot_personal_access_token_actions.revoke.success', pat_name: token.name)
    end

    test 'cannot revoke a personal access token when revocation fails' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project
      token = bot.user.personal_access_tokens.active.first

      # Mock the token's revoke! method to return false for this specific token
      PersonalAccessToken.any_instance.stubs(:revoke!).returns(false)

      assert_no_difference -> { bot.user.personal_access_tokens.active.count } do
        delete revoke_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
               as: :turbo_stream
      end

      assert_response :unprocessable_entity
    end

    test 'PAT panel removed after personal access token deletion' do
      sign_in users(:john_doe)
      bot = namespace_bots(:project1_bot0)
      namespace = bot.namespace.parent
      project = bot.namespace.project

      # Create a personal access token
      assert_difference -> { bot.user.personal_access_tokens.count } do
        post namespace_project_bot_personal_access_tokens_path(namespace, project, bot),
             params: { personal_access_token: {
               name: 'Test Token',
               scopes: ['read_api']
             } },
             as: :turbo_stream
      end

      assert_response :success
      assert_select '#access-token-section > div', count: 1

      token = bot.user.personal_access_tokens.active.last

      # Delete the personal access token via HTTP
      assert_difference -> { bot.user.personal_access_tokens.active.count }, -1 do
        delete revoke_namespace_project_bot_personal_access_token_path(namespace, project, bot, token),
               as: :turbo_stream
      end

      assert_response :success
      assert_select '#access-token-section > div', count: 0
    end

    test 'response should be not found when trying to destroy a bot account with a non-existent id' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project2)

      delete namespace_project_bot_path(namespace, project, id: 0, format: :turbo_stream)

      assert_response :not_found
    end

    test 'should not destroy a bot account for a bot account that does not belong to the project' do
      sign_in users(:john_doe)

      namespace_bot = namespace_bots(:project1_bot0)

      namespace = groups(:group_one)
      project = projects(:project2)

      delete namespace_project_bot_path(namespace, project, id: namespace_bot.id, format: :turbo_stream)

      assert_response :not_found
    end

    test 'accessing bots index on invalid page causes pagy overflow redirect at project level' do
      sign_in users(:john_doe)

      namespace = groups(:group_one)
      project = projects(:project1)

      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get namespace_project_bots_path(namespace, project, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
