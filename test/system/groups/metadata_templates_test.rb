# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class MetadataTemplatesTest < ApplicationSystemTestCase
    include ActionView::Helpers::SanitizeHelper

    def setup
      @user = users(:john_doe)
      login_as @user
    end

    test 'should display metadata templates associated with the group' do
      group = groups(:group_one)
      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_selector 'table thead tr th', count: 6
      assert_selector 'table tbody tr', count: group.metadata_templates.count

      group.metadata_templates.each do |metadata_template|
        assert_selector 'table tbody tr td:nth-child(1)', text: metadata_template.name
      end
    end

    test 'should not display metadata templates listing table if no metadata templates associated with the group' do
      group = groups(:group_five)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_no_selector 'table'

      assert_selector "div[class='empty_state_message']", count: 1

      assert_text I18n.t('metadata_templates.table.empty.title', namespace_type: group.type.downcase)
      assert_text I18n.t('metadata_templates.table.empty.description', namespace_type: group.type.downcase)
    end

    test 'should sort a list of metadata templates' do
      group = groups(:group_two)
      metadata_template1 = metadata_templates(:group_two_metadata_template1)
      metadata_template2 = metadata_templates(:group_two_metadata_template2)

      visit group_metadata_templates_url(group)

      strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary.one', count: 2))
      assert_selector 'table tbody tr', count: 2
      assert_selector 'table thead th:first-child svg.arrow-up-icon'

      assert_selector 'table tbody tr:first-child td:first-child', text: metadata_template1.name
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: metadata_template1.description

      click_on I18n.t('metadata_templates.table_component.name')
      assert_selector 'table thead th:first-child svg.arrow-down-icon'

      assert_selector 'table tbody tr:first-child td:first-child', text: metadata_template2.name
      assert_selector 'table tbody tr:first-child td:nth-child(2)', text: metadata_template2.description

      click_on I18n.t('metadata_templates.table_component.created_by_email')
      assert_selector 'table thead th:has(svg.arrow-up-icon)',
                      text: I18n.t('metadata_templates.table_component.created_by_email').upcase

      assert_selector 'table tbody tr:first-child td:first-child', text: metadata_template1.name
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: metadata_template1.created_by.email

      click_on I18n.t('metadata_templates.table_component.created_by_email')
      assert_selector 'table thead th:has(svg.arrow-down-icon)',
                      text: I18n.t('metadata_templates.table_component.created_by_email').upcase

      assert_selector 'table tbody tr:first-child td:first-child', text: metadata_template2.name
      assert_selector 'table tbody tr:first-child td:nth-child(3)', text: metadata_template2.created_by.email
    end

    test 'should destroy metadata template associated with the group' do
      group = groups(:group_one)
      metadata_template = metadata_templates(:group_one_metadata_template0)

      visit group_metadata_templates_url(group)

      table_row = find(:table_row, [metadata_template.name])

      within table_row do
        assert_button I18n.t('common.actions.delete'), count: 1
        click_button I18n.t('common.actions.delete')
      end

      assert_text I18n.t(
        :'metadata_templates.table_component.remove_confirmation',
        template_name: metadata_template.name
      )

      click_button I18n.t('common.controls.confirm')

      assert_text I18n.t(
        :'concerns.metadata_template_actions.destroy.success',
        template_name: metadata_template.name
      )
    end

    test 'maintainer or higher can access the metadata template page and create new template' do
      group = groups(:group_one)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_selector 'button', text: I18n.t('groups.metadata_templates.index.new_button'), count: 1

      click_on I18n.t('groups.metadata_templates.index.new_button')

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      group.metadata_fields.each do |field|
        assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: field
        find("ul[aria-labelledby='#{available_label_id}'] li", text: field).click
      end

      click_button I18n.t('components.viral.sortable_list.list_component.add')
      find('input#metadata_template_name').fill_in with: 'Group Template011'
      click_button I18n.t('metadata_templates.new_template_dialog.submit_button')

      assert_text I18n.t(
        :'concerns.metadata_template_actions.create.success',
        template_name: 'Group Template011'
      )

      assert_selector 'table tbody tr td:nth-child(1)', text: 'Group Template011'

      assert_selector 'button', text: I18n.t('groups.metadata_templates.index.new_button'), focused: true
    end

    test 'cannot create a template with no fields selected' do
      group = groups(:group_one)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_selector 'button', text: I18n.t('groups.metadata_templates.index.new_button'), count: 1

      click_on I18n.t('groups.metadata_templates.index.new_button')

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      find('input#metadata_template_name').fill_in with: 'Newest template'

      assert_button I18n.t('metadata_templates.new_template_dialog.submit_button'), disabled: true
    end

    test 'cannot create a template with no template name entered' do
      group = groups(:group_one)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_selector 'button', text: I18n.t('groups.metadata_templates.index.new_button'), count: 1

      click_on I18n.t('groups.metadata_templates.index.new_button')

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      group.metadata_fields.each do |field|
        assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: field
        find("ul[aria-labelledby='#{available_label_id}'] li", text: field).click
      end

      click_button I18n.t('components.viral.sortable_list.list_component.add')

      click_button I18n.t('metadata_templates.new_template_dialog.submit_button')

      assert_text I18n.t('general.form.error_notification')
      assert_text I18n.t('errors.format', attribute: I18n.t('activerecord.attributes.metadata_template.name'),
                                          message: I18n.t('errors.messages.blank'))
    end

    test 'cannot create a template with duplicate fields with same ordering in another template' do
      group = groups(:group_one)
      existing_metadata_template = metadata_templates(:valid_group_metadata_template)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_button I18n.t('groups.metadata_templates.index.new_button')

      click_button I18n.t('groups.metadata_templates.index.new_button')

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      existing_metadata_template.fields.each do |field|
        assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: field
        find("ul[aria-labelledby='#{available_label_id}'] li", text: field).click
        click_button I18n.t('components.viral.sortable_list.list_component.add')
      end

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li",
                      count: group.metadata_fields.count - existing_metadata_template.fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: existing_metadata_template.fields.count

      find('input#metadata_template_name').fill_in with: 'New Group Template'
      click_button I18n.t('metadata_templates.new_template_dialog.submit_button')

      assert_text 'Fields already exist in another template with the same ordering'

      assert_no_selector "div[data-controller='viral--flash']"
      assert_no_selector 'div[data-test-selector="spinner"]'
      assert_no_text I18n.t('metadata_templates.table_component.spinner_message')
    end

    test 'move fields between available and selected lists' do
      group = groups(:group_one)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_button I18n.t('groups.metadata_templates.index.new_button')

      click_button I18n.t('groups.metadata_templates.index.new_button')

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.new_template_dialog.title')
      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0

      group.metadata_fields.each do |field|
        assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: field
        find("ul[aria-labelledby='#{available_label_id}'] li", text: field).click
      end

      click_button I18n.t('components.viral.sortable_list.list_component.add')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: group.metadata_fields.count

      group.metadata_fields.each do |field|
        assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", text: field
        find("ul[aria-labelledby='#{selected_label_id}'] li", text: field).click
      end
      click_button I18n.t('common.actions.remove')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: group.metadata_fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: 0
    end

    test 'cannot view the add new template button if no fields are available for the group' do
      group = groups(:group_two)

      visit group_metadata_templates_url(group)

      assert_selector 'h1', text: I18n.t('groups.metadata_templates.index.title')
      assert_selector 'span', text: I18n.t('groups.metadata_templates.index.subtitle')

      assert_no_selector 'a', text: I18n.t('groups.metadata_templates.index.new_button')
    end

    test 'should edit metadata template associated with the group' do
      group = groups(:group_one)
      metadata_template = metadata_templates(:group_one_metadata_template0)

      visit group_metadata_templates_url(group)

      table_row = find(:table_row, [metadata_template.name])
      within table_row do
        assert_button I18n.t('common.actions.edit'), count: 1
        click_button I18n.t('common.actions.edit')
      end

      assert_selector 'dialog h1', text: I18n.t('metadata_templates.edit_template_dialog.title')

      assert_text I18n.t('metadata_templates.form.description')

      available_label_id = find('p', text: I18n.t(:'metadata_templates.form.available'))[:id]
      selected_label_id = find('p', text: I18n.t(:'metadata_templates.form.selected'))[:id]

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li",
                      count: group.metadata_fields.count - metadata_template.fields.count
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: metadata_template.fields.count

      unselected_fields = group.metadata_fields.reject { |field| metadata_template.fields.include? field }

      unselected_fields.each do |field|
        assert_selector "ul[aria-labelledby='#{available_label_id}'] li", text: field
        find("ul[aria-labelledby='#{available_label_id}'] li", text: field).click
      end

      click_button I18n.t('components.viral.sortable_list.list_component.add')

      assert_selector "ul[aria-labelledby='#{available_label_id}'] li", count: 0
      assert_selector "ul[aria-labelledby='#{selected_label_id}'] li", count: group.metadata_fields.count

      fill_in 'Name', with: 'Group Template011'

      assert_button I18n.t('common.actions.update')
      click_button I18n.t('common.actions.update')

      assert_text I18n.t(
        :'concerns.metadata_template_actions.update.success',
        template_name: 'Group Template011'
      )

      table_row = find(:table_row, ['Group Template011'])

      within(table_row) do
        assert_text 'Group Template011'
        assert_button I18n.t('common.actions.edit'), focused: true
      end
    end
  end
end
