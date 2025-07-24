# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class HistoryTest < ApplicationSystemTestCase
    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
      @project = projects(:project1)

      @project.namespace.create_logidze_snapshot!
    end

    test 'can see the list of project change versions' do
      visit namespace_project_history_path(@namespace, @project)

      assert_selector 'h1', text: I18n.t(:'projects.history.index.title')

      within('#project_history') do
        assert_selector 'ol', count: 1
        assert_selector 'li', count: 1

        assert_selector 'span', text: I18n.t(:'components.history.link_text', version: 1)

        assert_selector 'p', text: I18n.t(:'components.history.created_by', type: 'Project', user: 'System')
      end
    end

    test 'can see modal with changes to project from previous version' do
      visit namespace_project_history_path(@namespace, @project)
      click_on 'Version 1'

      within('#history_modal') do
        assert_selector 'h1', text: I18n.t(:'components.history.link_text', version: 1)
        assert_selector 'p', text: I18n.t(:'projects.history.project_history_modal_description.project_created',
                                          user: 'System')

        assert_no_text I18n.t(:'components.history_version.previous_version')
        assert_text I18n.t(:'components.history_version.current_version', version: 1)

        assert_selector 'span[data-test-item-selector="key"]', text: 'name'
        assert_selector 'span[data-test-item-selector="key"]', text: 'path'
        assert_selector 'span[data-test-item-selector="key"]', text: 'type'
        assert_selector 'span[data-test-item-selector="key"]', text: 'owner_id'
        assert_selector 'span[data-test-item-selector="key"]', text: 'parent_id'
        assert_selector 'span[data-test-item-selector="key"]', text: 'description'
        assert_selector 'span[data-test-item-selector="key"]', text: 'puid'

        assert_selector 'span[data-test-item-selector="value"]', text: 'Project 1'
        assert_selector 'span[data-test-item-selector="value"]', text: 'project-1'
        assert_selector 'span[data-test-item-selector="value"]', text: 'Project'
        assert_selector 'span[data-test-item-selector="value"]', text: @project.namespace.owner.id
        assert_selector 'span[data-test-item-selector="value"]', text: @project.namespace.parent.id
        assert_selector 'span[data-test-item-selector="value"]', text: 'Project 1 description'
        assert_selector 'span[data-test-item-selector="value"]', text: @project.puid
      end
    end
  end
end
