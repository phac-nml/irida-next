# frozen_string_literal: true

require 'application_system_test_case'

# Thin browser smoke test for the V2 advanced search UI.
#
# Node interactions (add/remove/reindex/seed and the params shape) are covered by the faster JS
# suite (test/javascript/controllers/advanced_search/v2/builder_controller.test.js), and
# filtering/validation by the version-agnostic integration tests. This suite only asserts the
# browser-only behaviour those layers cannot: the dialog-controller -> builder Stimulus outlet
# wiring renders the builder from its <template>s on open, plus live-DOM accessibility.
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
end
