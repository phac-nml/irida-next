# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class BotsTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)
    end

    test 'can see a table listing of project bot accounts' do
      visit namespace_project_bots_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'tr', count: 20 + header_row_count

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tr', count: 1 + header_row_count

      assert_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/

      click_on I18n.t(:'components.pagination.previous')
      assert_selector 'tr', count: 20 + header_row_count
    end

    test 'can see an empty state for table listing of project bot accounts' do
      project = projects(:project2)
      visit namespace_project_bots_path(@namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'tr', count: 0

      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      within('div.empty_state_message') do
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.description')
      end
    end

    test 'can create a new project bot account' do
      project = projects(:project2)
      visit namespace_project_bots_path(@namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'projects.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.description')
      end

      click_link I18n.t(:'projects.bots.index.add_new_bot')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.description')

        fill_in 'Token Name', with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        all('input[type=checkbox]').each(&:click)

        click_button I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.submit')
      end

      assert_selector 'tr', count: 1 + header_row_count
    end

    test 'can\'t create a new project bot account without selecting scopes' do
      project = projects(:project2)
      visit namespace_project_bots_path(@namespace, project)

      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'projects.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'projects.bots.index.bot_listing.empty_state.description')
      end

      click_link I18n.t(:'projects.bots.index.add_new_bot')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.description')

        fill_in 'Token Name', with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        assert_html5_inputs_valid

        click_button I18n.t(:'projects.bots.index.bot_listing.new_bot_modal.submit')

        within('#new_bot_account-error-alert') do
          assert_text I18n.t(:'services.bots.create.required.scopes')
        end
      end
    end

    test 'can delete a project bot account' do
      visit namespace_project_bots_path(@namespace, @project)
      assert_selector 'h1', text: I18n.t(:'projects.bots.index.title')
      assert_selector 'p', text: I18n.t(:'projects.bots.index.subtitle')

      within('table') do
        first('button.Viral-Dropdown--icon').click
        click_link 'Remove'
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'projects.bots.destroy.success')

      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
    end
  end
end
