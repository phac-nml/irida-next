# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MetadataTemplatesTest < ApplicationSystemTestCase
    def setup
      @user = users(:john_doe)
      login_as @user
    end

    test 'should display metadata templates associated with the group' do
      group = groups(:group_one)
      metadata_template = metadata_templates(:group_one_metadata_template0)
      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'p', text: I18n.t('groups.metadata_templates.index.subtitle')

      within('table thead tr') do
        assert_selector 'th', count: 6
      end

      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')

      within('table tbody') do
        assert_selector 'tr', count: 2
      end

      assert_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/

      click_on I18n.t(:'components.pagination.previous')

      within('table tbody') do
        assert_selector 'tr', count: 20
      end

      within('table tbody tr:first-child td:nth-child(1)') do
        assert_text metadata_template.name
      end
    end

    test 'should not display metadata templates listing table if no metadata templates associated with the group' do
      group = groups(:group_two)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'p', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_no_selector 'table'

      assert_selector "div[class='empty_state_message']", count: 1

      assert_text I18n.t('metadata_templates.table.empty.title', namespace_type: group.type.downcase)
      assert_text I18n.t('metadata_templates.table.empty.description', namespace_type: group.type.downcase)
    end

    test 'should sort a list of metadata templates' do
      group = groups(:group_one)
      metadata_template1 = metadata_templates(:group_one_metadata_template0)
      metadata_template20 = metadata_templates(:group_one_metadata_template20)
      metadata_template22 = metadata_templates(:valid_group_metadata_template)

      visit group_metadata_templates_url(group)

      assert_text 'Displaying items 1-20 of 22 in total'
      assert_selector 'table tbody tr', count: 20
      assert_selector 'table thead th:first-child svg.icon-arrow_up'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template1.name
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: metadata_template1.description
      end

      sort_link = find('table thead th:nth-child(1) a')
      sort_link.trigger('click')
      assert_selector 'table thead th:first-child svg.icon-arrow_down'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template22.name
        assert_selector 'tr:first-child td:nth-child(2)',
                        text: metadata_template22.description
      end

      sort_link = find('table thead th:nth-child(3) a')
      sort_link.trigger('click')
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_up'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template20.name
        assert_selector 'tr:first-child td:nth-child(3)',
                        text: metadata_template20.created_by.email
      end

      sort_link = find('table thead th:nth-child(3) a')
      sort_link.trigger('click')
      assert_selector 'table thead th:nth-child(3) svg.icon-arrow_down'

      within('table tbody') do
        assert_selector 'tr:first-child td:first-child', text: metadata_template22.name
        assert_selector 'tr:first-child td:nth-child(3)',
                        text: metadata_template22.created_by.email
      end
    end
  end
end
