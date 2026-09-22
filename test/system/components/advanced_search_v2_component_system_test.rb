# frozen_string_literal: true

require 'application_system_test_case'

# Browser coverage for the Rails-rendered builder, its nested Stimulus controllers,
# and dialog lifecycle. Isolated builder logic remains covered by the JS suite.
class AdvancedSearchV2ComponentSystemTest < ApplicationSystemTestCase
  GROUPS = "fieldset[data-advanced-search--v2--builder-target='groupsContainer']"
  CONDITIONS = "fieldset[data-advanced-search--v2--builder-target='conditionsContainer']"

  def setup
    Flipper.enable(:advanced_search_v2)
    Flipper.enable(:advanced_search_with_auto_complete)
  end

  test 'opening the dialog renders the builder from the outlet and is accessible' do
    visit('rails/view_components/advanced_search_component/v2_default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v2.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v2.title')
      within 'dialog' do
        assert_accessible

        # The dialog controller drives the host-agnostic builder through the Stimulus outlet:
        # on open it clones the server-rendered groups/conditions into the live DOM.
        assert_text I18n.t('components.advanced_search_component.v2.intro', subject: 'samples')
        assert_text I18n.t('components.advanced_search_component.v2.group_match_all')

        assert_selector GROUPS, count: 2
        within all(GROUPS)[0] do
          assert_selector CONDITIONS, count: 3
        end
        within all(GROUPS)[1] do
          assert_selector CONDITIONS, count: 1
        end
      end
    end
  end

  test 'removing preceding nodes preserves live combobox and list input identities' do
    open_preview(:v2_default)

    within 'dialog' do
      group = all(GROUPS)[1]
      within group do
        click_button I18n.t('components.advanced_search_component.v2.add_condition_button')
        assert_selector CONDITIONS, count: 2
      end
      condition = group.all(CONDITIONS)[1]
      within condition do
        choose_field('country')
        find("select[name$='[operator]']").find("option[value='in']").select_option
        find("input[data-list-input-target='input']").send_keys('Canada', ',')
        assert_selector '.search-tag', text: 'Canada'
      end
      original_ids = condition.all('[id]', visible: :all).pluck(:id)
      value_name = 'q[groups_attributes][1][conditions_attributes][1][value][]'

      within group.all(CONDITIONS).first do
        click_button I18n.t('components.advanced_search_component.v2.remove_condition_aria_label')
      end
      within all(GROUPS).first do
        click_button I18n.t('components.advanced_search_component.v2.remove_group_button')
      end

      assert_selector GROUPS, count: 1
      assert_selector CONDITIONS, count: 1
      assert_equal original_ids, condition.all('[id]', visible: :all).pluck(:id)
      within condition do
        find("input[data-list-input-target='input']").send_keys('Mexico', ',')
        assert_selector '.search-tag', text: 'Mexico'
        assert_equal %w[Canada Mexico], all("input[type='hidden'][name='#{value_name}']", visible: :all).map(&:value)

        # Filtering clones the combobox's cached options; their references must still
        # point at the live widget after its preceding group and condition disappear.
        combobox = find("input[role='combobox']")
        combobox.send_keys([:ctrl, 'a'], :delete, 'age')
        assert_selector "[role='option'][data-value='metadata.age']"
        assert_combobox_references
        find("[role='option'][data-value='metadata.age']").click
        find("select[name$='[operator]']").find("option[value='between']").select_option
        assert_selector "input[name='#{value_name}']", count: 2
        find("input[id$='from_value']").fill_in with: '10'
        find("input[id$='to_value']").fill_in with: '20'
      end

      submitted_fields = page.evaluate_script(<<~JS)
        Array.from(new FormData(document.querySelector('#advanced-search-builder').closest('form')).entries())
      JS
      query_fields = submitted_fields.select { |name, _value| name.start_with?('q[groups_attributes]') }
      condition_name = 'q[groups_attributes][1][conditions_attributes][1]'
      assert_equal [
        ["#{condition_name}[field]", 'metadata.age'],
        ["#{condition_name}[operator]", 'between'],
        [value_name, '10'],
        [value_name, '20']
      ], query_fields

      within group do
        click_button I18n.t('components.advanced_search_component.v2.add_condition_button')
        assert_selector CONDITIONS, count: 2
      end
      click_button I18n.t('components.advanced_search_component.v2.add_group_button')
      assert_selector GROUPS, count: 2
      field_names = all("input[type='hidden'][name$='[field]']", visible: :all).pluck(:name)
      assert_equal field_names.uniq, field_names
      assert_includes field_names, 'q[groups_attributes][1][conditions_attributes][1][field]'
    end
  end

  test 'stored list values close without confirmation and prompt after an edit' do
    open_preview(:v2_list)
    within 'dialog' do
      assert_selector '.search-tag', count: 2
      click_button I18n.t('components.dialog.close')
    end
    assert_no_selector 'dialog[open]'

    click_button I18n.t('components.advanced_search_component.v2.title')
    within 'dialog' do
      assert_selector '.search-tag', count: 2
      within first('.search-tag') do
        click_button I18n.t('common.actions.remove')
      end
      dismiss_confirm(I18n.t('components.advanced_search_component.v2.confirm_close_text')) do
        click_button I18n.t('components.dialog.close')
      end
      assert_selector '.search-tag', text: 'Mexico'
      assert_no_selector '.search-tag', text: 'Canada'
    end
    assert_selector 'dialog[open]'
  end

  private

  def open_preview(preview)
    visit("rails/view_components/advanced_search_component/#{preview}")
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t('components.advanced_search_component.v2.title')
    end
    assert_selector 'dialog[open]'
  end

  def choose_field(label)
    combobox = find("input[role='combobox']")
    combobox.send_keys([:ctrl, 'a'], :delete, label)
    find("[role='option']", text: label, exact_text: true).click
  end

  def assert_combobox_references
    all('[aria-controls], [aria-labelledby], [aria-activedescendant], label[for]', visible: :all).each do |element|
      %w[aria-controls aria-labelledby aria-activedescendant for].each do |attribute|
        element[attribute].to_s.split.each do |id|
          assert_selector "[id='#{id}']", visible: :all, count: 1
        end
      end
    end
  end
end
