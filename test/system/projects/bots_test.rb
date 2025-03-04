# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class BotsTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
      @project2 = projects(:project2)
      @project_bot = namespace_bots(:project1_bot0)
      @project_bot_active_tokens = @project_bot.user.personal_access_tokens.active
    end

    test 'can see a table listing of project bot accounts' do
      visit namespace_project_bots_path(@namespace, @project)

      # header and description
      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      # table
      assert_selector 'tr', count: 20 + header_row_count

      # pagy
      assert_link exact_text: I18n.t(:'viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.previous')

      # second page of table
      click_on I18n.t(:'viral.pagy.pagination_component.next')
      assert_selector 'tr', count: 1 + header_row_count

      # pagy updated
      assert_link exact_text: I18n.t(:'viral.pagy.pagination_component.previous')
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.next')

      # pagy previous works
      click_on I18n.t(:'viral.pagy.pagination_component.previous')
      assert_selector 'tr', count: 20 + header_row_count
    end

    test 'can see an empty state for table listing of project bot accounts' do
      visit namespace_project_bots_path(@namespace, @project2)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'tr', count: 0

      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.next')
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.previous')

      within('div.empty_state_message') do
        assert_text I18n.t(:'bots.index.table.empty_state.title')
        assert_text I18n.t(:'bots.index.table.empty_state.description')
      end
    end

    test 'can create a new project bot account' do
      ### VERIFY START ###
      visit namespace_project_bots_path(@namespace, @project2)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'projects.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'bots.index.table.empty_state.title')
        assert_text I18n.t(:'bots.index.table.empty_state.description')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t(:'projects.bots.index.add_new_bot')

      assert_selector '#dialog'
      within('#dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.description')

        fill_in I18n.t('projects.bots.index.bot_listing.new_bot_modal.token_name'), with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        all('input[type=checkbox]').each(&:click)

        click_button I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.submit')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_no_selector '#dialog'

      assert_selector '#access-token-section div'
      within('#access-token-section') do
        bot_account_name = @project2.namespace.bots.last.email
        assert_selector 'h2', text: I18n.t('projects.bots.index.access_token_section.label', bot_name: bot_account_name)
        assert_selector 'p', text: I18n.t('projects.bots.index.access_token_section.description')
        assert_selector 'button', text: I18n.t('components.token.copy')
      end

      assert_selector 'tr', count: 1 + header_row_count
      ### VERIFY END ###
    end

    test 'can\'t create a new project bot account without selecting scopes' do
      ### SETUP START ###
      visit namespace_project_bots_path(@namespace, @project2)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'projects.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'bots.index.table.empty_state.title')
        assert_text I18n.t(:'bots.index.table.empty_state.description')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      click_link I18n.t(:'projects.bots.index.add_new_bot')

      assert_selector '#dialog'
      within('#dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.description')

        fill_in I18n.t('projects.bots.index.bot_listing.new_bot_modal.token_name'), with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        assert_html5_inputs_valid

        click_button I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.submit')
        ### ACTIONS END ###

        ### VERIFY START ###
        assert_selector '#new_bot_account-error-alert'
        within('#new_bot_account-error-alert') do
          assert_text I18n.t(:'services.bots.create.required.scopes')
        end
      end
      ### VERIFY END ###
    end

    test 'can delete a project bot account' do
      ### SETUP START ###
      visit namespace_project_bots_path(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within('table tbody tr:first-child td:last-child') do
        click_link I18n.t(:'bots.index.table.actions.destroy')
      end

      assert_selector '#dialog'
      within('#dialog') do
        click_button I18n.t('bots.destroy_confirmation.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success message
      assert_text I18n.t(:'concerns.bot_actions.destroy.success')
      # bot number decreased by 1
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      # no pagy next/previous buttons since only 1 page for table
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.previous')
      assert_no_link exact_text: I18n.t(:'viral.pagy.pagination_component.next')
      ### VERIFY END ###
    end

    test 'can view personal access tokens for bot account' do
      ### SETUP START ###
      token = @project_bot_active_tokens.first
      visit namespace_project_bots_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within "tr[id='#{@project_bot.id}']" do
        click_link @project_bot_active_tokens.count.to_s
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector '#bot_tokens_dialog'
      within('#bot_tokens_dialog') do
        assert_selector 'h1', text: I18n.t('projects.bots.index.personal_access_tokens_listing_modal.title')
        assert_selector 'p',
                        text: I18n.t(
                          'projects.bots.index.personal_access_tokens_listing_modal.description',
                          bot_account: @project_bot.user.email
                        )

        within('table') do
          assert_selector 'tr', count: 2

          within "tr[id='#{token.id}']" do
            assert_equal 'Valid PAT0', token.name
            assert_equal 'read_api, api', token.scopes.join(', ')

            assert_equal Time.zone.now.strftime(
              I18n.t('time.formats.full_date')
            ), token.created_at.strftime(
              I18n.t('time.formats.full_date')
            )

            assert_equal 10.days.from_now.to_date.strftime(
              I18n.t('time.formats.full_date')
            ), token.expires_at.strftime(
              I18n.t('time.formats.full_date')
            )
          end
        end
      end
      ### VERIFY END ###
    end

    test 'can generate a new personal access token for bot account' do
      ### SETUP START ###
      initial_token_count = @project_bot_active_tokens.count
      visit namespace_project_bots_path(@namespace, @project)
      # verify page and table loaded
      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within "tr[id='#{@project_bot.id}']" do
        click_link I18n.t('bots.index.table.actions.generate_new_token')
      end

      # verify dialog rendered
      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.title')

        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.description',
                           bot_account: @project_bot.user.email)
        # fill token params
        fill_in I18n.t('projects.bots.index.bot_listing.new_bot_modal.token_name'), with: 'Newest token'
        all('input[type=checkbox]').each(&:click)
        click_button I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.submit')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      assert_selector '#access-token-section div'
      within('#access-token-section') do
        assert_selector 'h2', text: I18n.t('projects.bots.index.access_token_section.label',
                                           bot_name: @project_bot.user.email)
        assert_selector 'p', text: I18n.t('projects.bots.index.access_token_section.description')
        assert_selector 'button', text: I18n.t('components.token.copy')
      end
      # verify token count increased
      within "tr[id='#{@project_bot.id}'] td:nth-child(2)" do
        assert_text (initial_token_count + 1).to_s
      end
      ### VERIFY END ###
    end

    test 'can revoke a personal access token' do
      ### SETUP START ###
      token = @project_bot_active_tokens.first
      initial_token_count = @project_bot_active_tokens.count
      visit namespace_project_bots_path(@namespace, @project)
      # verify page rendered
      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      ### SETUP END ###

      ### ACTIONS START ###
      within "tr[id='#{@project_bot.id}'] td:nth-child(2)" do
        assert_text initial_token_count.to_s
        # open bot PAT dialog
        click_link initial_token_count.to_s
      end

      # verify bots token dialog rendered
      assert_selector '#bot_tokens_dialog'
      within('#bot_tokens_dialog') do
        # verify PAT table rendered
        assert_selector '#personal_access_tokens'
        within('table tbody') do
          assert_selector 'tr', count: 1
        end
        # revoke PAT
        within("table tbody tr[id='#{token.id}']") do
          click_link I18n.t('personal_access_tokens.table.revoke')
        end
      end

      # verify revoke dialog rendered
      assert_selector '#revoke_confirmation_dialog'
      within('#revoke_confirmation_dialog') do
        assert_text I18n.t('personal_access_tokens.revoke_confirmation.title')
        # revoke
        click_button I18n.t('personal_access_tokens.revoke_confirmation.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # success msg
      assert_selector '#personal-access-token-alert'
      within('#personal-access-token-alert') do
        assert_text I18n.t('concerns.bot_personal_access_token_actions.revoke.success', pat_name: token.name)
      end

      # verify token count decreased
      within "tr[id='#{@project_bot.id}'] td:nth-child(2)" do
        assert_text (initial_token_count - 1).to_s
      end
      ### VERIFY END ###
    end

    test 'PAT panel removed after personal access token revoke' do
      ### SETUP START ###
      visit namespace_project_bots_path(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      # PAT turbo frame present with no content
      assert_selector '#access-token-section'
      assert_no_selector '#access-token-section div'
      # create new PAT to render PAT panel
      within "tr[id='#{@project_bot.id}']" do
        click_link I18n.t('bots.index.table.actions.generate_new_token')
      end

      # verify dialog rendered
      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.title')
        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.description',
                           bot_account: @project_bot.user.email)

        fill_in I18n.t('projects.bots.index.bot_listing.new_bot_modal.token_name'), with: 'Newest token'
        all('input[type=checkbox]').each(&:click)
        click_button I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.submit')
      end

      # PAT panel now present
      # additional asserts to prevent flakes
      assert_selector '#access-token-section div'
      within('#access-token-section') do
        assert_text I18n.t('projects.bots.index.access_token_section.label', bot_name: @project_bot.user.email)
        assert_text I18n.t('projects.bots.index.access_token_section.description')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # additional asserts to prevent flakes
      assert_selector '#bots-table'
      assert_selector '#bots-table table tbody tr', count: 20
      within "tr[id='#{@project_bot.id}']" do
        # click active tokens number
        click_link @project_bot_active_tokens.count.to_s
      end

      # bot's current PATs dialog
      assert_selector '#bot_tokens_dialog'
      within('#bot_tokens_dialog') do
        assert_selector '#personal_access_tokens'
        within('table tbody') do
          assert_selector 'tr', count: 2
        end
        # revoke a PAT
        within("table tbody tr[id='#{@project_bot_active_tokens.first.id}']") do
          click_link I18n.t('personal_access_tokens.table.revoke')
        end
      end

      assert_selector '#revoke_confirmation_dialog'
      within('#revoke_confirmation_dialog') do
        assert_text I18n.t('personal_access_tokens.revoke_confirmation.title')
        click_button I18n.t('personal_access_tokens.revoke_confirmation.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # PAT panel no longer contains content
      assert_selector '#access-token-section'
      assert_no_selector '#access-token-section div'
      ### VERIFY END ###
    end

    test 'PAT panel removed after bot destroy' do
      ### SETUP START ###
      visit namespace_project_bots_path(@namespace, @project)
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 21,
                                                                           locale: @user.locale))
      # PAT turbo frame present with no content
      assert_selector '#access-token-section'
      assert_no_selector '#access-token-section div'
      # create new PAT to render PAT panel
      within "table tbody tr[id='#{@project_bot.id}']" do
        click_link I18n.t('bots.index.table.actions.generate_new_token')
      end

      # verify dialog rendered
      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.title')
        assert_text I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.description',
                           bot_account: @project_bot.user.email)
        # fill in PAT values
        fill_in I18n.t('projects.bots.index.bot_listing.new_bot_modal.token_name'), with: 'Newest token'
        all('input[type=checkbox]').each(&:click)
        click_button I18n.t('projects.bots.index.bot_listing.generate_personal_access_token_modal.submit')
      end

      # PAT panel now present
      assert_selector '#access-token-section div'
      # additional asserts to prevent flakes
      within('#access-token-section') do
        assert_text I18n.t('projects.bots.index.access_token_section.label', bot_name: @project_bot.user.email)
        assert_text I18n.t('projects.bots.index.access_token_section.description')
      end
      ### SETUP END ###

      ### ACTIONS START ###
      # additional asserts to prevent flakes
      assert_selector '#bots-table'
      assert_selector '#bots-table table tbody tr', count: 20
      assert_selector "#bots-table table tbody tr[id='#{@project_bot.id}']"
      within("#bots-table table tbody tr[id='#{@project_bot.id}']") do
        sleep 1
        assert_text I18n.t(:'bots.index.table.actions.destroy')
        # destroy bot
        find('a', text: I18n.t(:'bots.index.table.actions.destroy')).click
      end

      # confirm destroy bot
      assert_selector '#dialog'
      within('#dialog') do
        assert_text I18n.t('bots.destroy_confirmation.description', bot_name: @project_bot.user.email)
        click_button I18n.t('bots.destroy_confirmation.submit_button')
      end
      ### ACTIONS END ###

      ### VERIFY START ###
      # confirm bot destroyed
      assert_text strip_tags(I18n.t(:'viral.pagy.limit_component.summary', from: 1, to: 20, count: 20,
                                                                           locale: @user.locale))
      # PAT panel no longer contains content
      assert_selector '#access-token-section'
      assert_no_selector '#access-token-section div'
      ### VERIFY END ###
    end
  end
end
