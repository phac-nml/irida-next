# frozen_string_literal: true

require 'application_system_test_case'

# Thin browser coverage for the V2 advanced search UI. Filtering/validation behaviour is
# covered by the version-agnostic integration tests (see test/integration/**/samples_test.rb);
# this suite verifies the decoupled V2 dialog/builder interactions only.
class AdvancedSearchV2ComponentSystemTest < ApplicationSystemTestCase
  GROUPS = "fieldset[data-advanced-search--v2--builder-target='groupsContainer']"
  CONDITIONS = "fieldset[data-advanced-search--v2--builder-target='conditionsContainer']"

  def setup
    Flipper.enable(:advanced_search_v2)
    Flipper.enable(:advanced_search_with_auto_complete)
  end

  test 'renders the decoupled v2 dialog with existing groups and conditions' do
    visit('rails/view_components/advanced_search_component/v2_default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v2.title')

      assert_selector 'dialog h1', text: I18n.t(:'components.advanced_search_component.v2.title')
      within 'dialog' do
        assert_accessible

        # The subject-aware intro (OR-between-groups) and the per-group helper (AND-within-group)
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

  test 'adds and removes groups and conditions' do
    visit('rails/view_components/advanced_search_component/v2_default')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v2.title')

      within 'dialog' do
        within all(GROUPS)[0] do
          within all(CONDITIONS)[0] do
            find("button[data-action='advanced-search--v2--builder#removeCondition']").click
          end
          assert_selector CONDITIONS, count: 2
        end

        within all(GROUPS)[1] do
          click_button I18n.t(:'components.advanced_search_component.v2.remove_group_button')
        end
        assert_selector GROUPS, count: 1

        click_button I18n.t(:'components.advanced_search_component.v2.add_group_button')
        assert_selector GROUPS, count: 2

        within all(GROUPS)[1] do
          assert_selector CONDITIONS, count: 1
          click_button I18n.t(:'components.advanced_search_component.v2.add_condition_button')
          assert_selector CONDITIONS, count: 2
        end
      end
    end
  end

  test 'seeds an empty group and condition when no query exists' do
    visit('rails/view_components/advanced_search_component/v2_empty')
    within 'div[data-controller-connected="true"]' do
      click_button I18n.t(:'components.advanced_search_component.v2.title')

      within 'dialog' do
        assert_selector GROUPS, count: 1
        within all(GROUPS)[0] do
          assert_selector CONDITIONS, count: 1
        end
      end
    end
  end
end
