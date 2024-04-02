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

    test 'can see a list of project bot accounts' do
      visit namespace_project_bots_path(@namespace, @project)
      pause
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

    test 'can create a new project bot account' do
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
