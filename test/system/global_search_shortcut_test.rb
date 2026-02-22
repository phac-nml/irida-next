# frozen_string_literal: true

require 'application_system_test_case'

class GlobalSearchShortcutTest < ApplicationSystemTestCase
  setup do
    Flipper.enable(:global_search)
    login_as users(:john_doe)
  end

  teardown do
    Flipper.disable(:global_search)
  end

  test 'ctrl+k opens dialog on nested pages and escape clears and closes it' do
    visit '/-/groups/group-1'

    trigger_global_search_shortcut

    dialog = find("dialog[data-global-search-shortcut-target='dialog'][open]", visible: :all)

    within(dialog) do
      find('summary', text: 'Filters').click
      find("input[name='q']").set('Shigella')
      uncheck('Group')
    end

    find('body').send_keys(:escape)
    assert_no_selector "dialog[data-global-search-shortcut-target='dialog'][open]", visible: :all

    trigger_global_search_shortcut
    dialog = find("dialog[data-global-search-shortcut-target='dialog'][open]", visible: :all)

    within(dialog) do
      assert_equal '', find("input[name='q']").value
      assert find("input[name='types[]'][value='groups']", visible: :all).checked?
    end
  end

  test 'enter submits dialog form to global search route' do
    visit '/-/projects/project-1'

    trigger_global_search_shortcut

    within("dialog[data-global-search-shortcut-target='dialog'][open]") do
      find("input[name='q']").set('Project 1')
      find("input[name='q']").send_keys(:enter)
    end

    assert_current_path(%r{\A/-/search\?})
    assert_selector '[data-global-search-version="g1"]'
    assert_field 'q', with: 'Project 1'
  end

  test 'dialog shortcut is unavailable when global search feature flag is disabled' do
    Flipper.disable(:global_search)
    visit '/-/groups/group-1'

    trigger_global_search_shortcut

    assert_no_selector "dialog[data-global-search-shortcut-target='dialog'][open]", visible: :all
  end

  private

  def trigger_global_search_shortcut
    page.execute_script(<<~JS)
      window.dispatchEvent(new KeyboardEvent("keydown", {
        key: "k",
        ctrlKey: true,
        bubbles: true
      }));
    JS
  end
end
