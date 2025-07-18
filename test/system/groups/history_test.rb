# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class HistoryTest < ApplicationSystemTestCase
    def setup
      @user = users(:john_doe)
      login_as @user
      @group = groups(:group_one)

      @group.create_logidze_snapshot!
    end

    test 'can see the list of group change versions' do
      visit group_history_path(@group)

      assert_selector 'h1', text: I18n.t(:'groups.history.index.title')

      within('#group_history') do
        assert_selector 'ol', count: 1
        assert_selector 'li', count: 1

        assert_selector 'span', text: I18n.t(:'components.history.link_text', version: 1)

        assert_selector 'p', text: I18n.t(:'components.history.created_by', type: 'Group', user: 'System')
      end
    end

    test 'can see group history version changes' do
      visit group_history_path(@group)

      click_on 'Version 1'

      within('#history_modal') do
        assert_selector 'h1', text: I18n.t(:'components.history.link_text', version: 1)
        assert_selector 'p', text: I18n.t(:'groups.history.group_history_modal_description.group_created',
                                          user: 'System')

        assert_no_text I18n.t(:'components.history_version.previous_version')
        assert_text I18n.t(:'components.history_version.current_version', version: 1)

        assert_selector 'span[data-test-item-selector="key"]', text: 'name'
        assert_selector 'span[data-test-item-selector="key"]', text: 'path'
        assert_selector 'span[data-test-item-selector="key"]', text: 'type'
        assert_selector 'span[data-test-item-selector="key"]', text: 'owner_id'
        assert_selector 'span[data-test-item-selector="key"]', text: 'description'

        assert_selector 'span[data-test-item-selector="value"]', text: 'Group 1'
        assert_selector 'span[data-test-item-selector="value"]', text: 'group-1'
        assert_selector 'span[data-test-item-selector="value"]', text: 'Group'
        assert_selector 'span[data-test-item-selector="value"]', text: @group.owner.id
        assert_selector 'span[data-test-item-selector="value"]', text: 'Group 1 description'
      end
    end
  end
end
