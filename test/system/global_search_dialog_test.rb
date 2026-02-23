# frozen_string_literal: true

require 'application_system_test_case'

class GlobalSearchDialogTest < ApplicationSystemTestCase
  setup do
    Flipper.enable(:global_search)
    login_as users(:john_doe)
  end

  teardown do
    Flipper.disable(:global_search)
  end

  test 'dialog has accessible label and heading' do
    visit '/-/groups/group-1'

    trigger_global_search_shortcut

    dialog = find("dialog[data-global-search-dialog-target='dialog'][open]", visible: :all)

    assert_equal 'global-search-dialog-title', dialog['aria-labelledby']

    within(dialog) do
      heading = find('#global-search-dialog-title', visible: :all)
      assert heading.matches_css?('.sr-only', wait: 0)
      assert_selector "label[for='global-search-dialog-query'].sr-only", visible: :all
    end
  end

  test 'slash opens dialog on nested pages' do
    visit '/-/groups/group-1'

    trigger_slash_shortcut

    assert_selector "dialog[data-global-search-dialog-target='dialog'][open]", visible: :all
  end

  test 'global search shortcuts ignore repeated and composing key events' do
    visit '/-/groups/group-1'

    trigger_keydown(key: 'k', ctrl_key: true, repeat: true)
    assert_no_selector "dialog[data-global-search-dialog-target='dialog'][open]", visible: :all

    trigger_keydown(key: 'k', ctrl_key: true, composing: true)
    assert_no_selector "dialog[data-global-search-dialog-target='dialog'][open]", visible: :all
  end

  test 'ctrl+k opens dialog on nested pages and escape clears and closes it' do
    visit '/-/groups/group-1'

    trigger_global_search_shortcut

    dialog = find("dialog[data-global-search-dialog-target='dialog'][open]", visible: :all)

    within(dialog) do
      find('summary', text: 'Filters').click
      find("input[name='q']").set('Shigella')
      uncheck('Group')
    end

    find('body').send_keys(:escape)
    assert_no_selector "dialog[data-global-search-dialog-target='dialog'][open]", visible: :all

    trigger_global_search_shortcut
    dialog = find("dialog[data-global-search-dialog-target='dialog'][open]", visible: :all)

    within(dialog) do
      assert_equal '', find("input[name='q']").value
      assert find("input[name='types[]'][value='groups']", visible: :all).checked?
    end
  end

  test 'enter submits dialog form to global search route' do
    visit '/-/projects/project-1'

    trigger_global_search_shortcut

    within("dialog[data-global-search-dialog-target='dialog'][open]") do
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

    assert_no_selector "dialog[data-global-search-dialog-target='dialog'][open]", visible: :all
  end

  private

  def trigger_global_search_shortcut
    trigger_keydown(key: 'k', ctrl_key: true)
  end

  def trigger_slash_shortcut
    trigger_keydown(key: '/')
  end

  def trigger_keydown(options)
    page.execute_script(keydown_dispatch_script, options)
  end

  def keydown_dispatch_script
    <<~JS
      const options = arguments[0];
      const event = new KeyboardEvent("keydown", {
        key: options.key,
        code: options.code,
        ctrlKey: Boolean(options.ctrl_key),
        metaKey: Boolean(options.meta_key),
        altKey: Boolean(options.alt_key),
        shiftKey: Boolean(options.shift_key),
        repeat: Boolean(options.repeat),
        bubbles: true
      });

      if (options.composing) {
        try {
          Object.defineProperty(event, "isComposing", { value: true });
        } catch (_error) {
          // Ignore unsupported property override in browser driver.
        }
      }

      window.dispatchEvent(event);
    JS
  end
end
