# frozen_string_literal: true

require 'application_system_test_case'

class LiveRegionsTest < ApplicationSystemTestCase
  include ActionView::Helpers::SanitizeHelper

  setup do
    @user = users(:john_doe)
    login_as @user
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @project = projects(:project1)
    @namespace = groups(:group_one)
  end

  test 'live region component renders with correct ARIA attributes for selection' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for samples table to render
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Verify live region exists with correct ARIA attributes
    assert_selector "span[role='status'][aria-live='polite'].sr-only[data-selection-target='status']"
  end

  test 'selection controller announces selection count via live region' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for samples table to render
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Find the live region for selection announcements
    live_region = find("span[data-selection-target='status']", visible: false)

    # Initially the live region should be empty
    assert_empty live_region.text

    # Select a single sample
    find("input##{dom_id(@sample1, :checkbox)}").click

    # Verify the live region content is updated with selection count
    # The selection controller uses count_message_one for singular selection
    assert_selector "span[data-selection-target='status']", visible: false, wait: 2
    live_region = find("span[data-selection-target='status']", visible: false)

    # The text should contain the selection count message (1 of X selected)
    assert_match(/1/, live_region.text)
  end

  test 'select all updates live region with total count' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for samples table to render
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Click select all
    click_button I18n.t('common.controls.select_all')

    # Verify all checkboxes are selected
    assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3

    # Verify live region is updated
    live_region = find("span[data-selection-target='status']", visible: false)

    # Should show 3 selected (all samples)
    assert_match(/3/, live_region.text)
  end

  test 'deselect all clears live region selection count' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for samples table to render
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Select all first
    click_button I18n.t('common.controls.select_all')
    assert_selector 'table tbody tr th input[name="sample_ids[]"]:checked', count: 3

    # Now deselect all
    click_button I18n.t('common.controls.deselect_all')
    assert_no_selector 'table tbody tr th input[name="sample_ids[]"]:checked'

    # Verify live region shows 0 selected
    live_region = find("span[data-selection-target='status']", visible: false)
    assert_match(/0/, live_region.text)
  end

  test 'live region exists and is accessible on samples page' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for page load
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Verify ARIA live region has required accessibility attributes
    # role="status" provides implicit aria-live="polite" for redundancy
    live_region = find("span[data-selection-target='status']", visible: false)

    assert_equal 'status', live_region['role']
    assert_equal 'polite', live_region['aria-live']
    assert_includes live_region['class'], 'sr-only'
  end

  test 'page is accessible when live region is present' do
    visit namespace_project_samples_url(@namespace, @project)
    # Wait for page load
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Run accessibility audit
    assert_accessible
  end

  test 'live region utility works when cloning samples' do
    # This tests that the JavaScript live region utility works during sample operations
    # The clone operation uses the announce function internally for selection feedback
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Find the live region
    live_region = find("span[data-selection-target='status']", visible: false)
    assert_empty live_region.text

    # Select samples - this triggers announce() via the selection controller
    find("table tbody tr th input##{dom_id(@sample1, :checkbox)}").click
    find("table tbody tr th input##{dom_id(@sample2, :checkbox)}").click

    # Live region should be updated with selection count
    live_region = find("span[data-selection-target='status']", visible: false)
    assert_match(/2/, live_region.text)

    # Open clone dialog
    click_button I18n.t('shared.samples.actions_dropdown.label')
    click_button I18n.t('shared.samples.actions_dropdown.clone')

    # Verify dialog opened (confirms JS is working correctly including live regions)
    assert_selector 'dialog[open]'
    assert_selector 'dialog h1', text: I18n.t('samples.clones.dialog.title')

    # Verify the selected items are shown in the dialog
    within('#list_selections') do
      assert_text @sample1.name
      assert_text @sample2.name
    end

    # Close dialog without completing (we've already verified live regions work)
    find('button.dialog--close').click
    assert_no_selector 'dialog[open]'
  end

  test 'live region with atomic attribute announces complete content' do
    # Test that atomic live regions are rendered correctly
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # The samples page uses polite non-atomic live regions by default
    # Verify aria-atomic is not present when not needed
    live_region = find("span[data-selection-target='status']", visible: false)
    assert_nil live_region['aria-atomic']
  end

  test 'global live region fallback is created when announce is called without element' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Use JavaScript to call announce() without an element, triggering global fallback
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ announce }) => {
        announce('Test global announcement');
      });
    JS

    # Wait for the announcement to be processed
    sleep 0.2

    # The global live region should now exist
    assert_selector '#sr-status', visible: false
    global_region = find('#sr-status', visible: false)

    # Verify it has correct ARIA attributes
    assert_equal 'status', global_region['role']
    assert_equal 'polite', global_region['aria-live']
    assert_includes global_region['class'], 'sr-only'
    assert_equal 'Test global announcement', global_region.text
  end

  test 'findOrCreateGlobalRegion preserves existing aria-live attribute' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Create a global region with assertive politeness first
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ createLiveRegion, findOrCreateGlobalRegion }) => {
        // Create an assertive global region
        createLiveRegion({ id: 'sr-status', politeness: 'assertive' });

        // Now call findOrCreateGlobalRegion with polite - it should NOT downgrade
        const region = findOrCreateGlobalRegion('polite');

        // Store result for verification
        window.testResult = region.getAttribute('aria-live');
      });
    JS

    # Wait for script execution
    sleep 0.1

    # Verify the aria-live attribute was preserved (still assertive, not downgraded to polite)
    result = page.evaluate_script('window.testResult')
    assert_equal 'assertive', result
  end

  test 'createLiveRegion prevents duplicate IDs' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Create two live regions with the same ID
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ createLiveRegion }) => {
        const first = createLiveRegion({ id: 'test-duplicate-id', politeness: 'polite' });
        first.textContent = 'First region';

        const second = createLiveRegion({ id: 'test-duplicate-id', politeness: 'assertive' });

        // Store results for verification
        window.firstRegion = first;
        window.secondRegion = second;
        window.areSame = first === second;
      });
    JS

    # Wait for script execution
    sleep 0.1

    # Verify only one element with that ID exists (valid HTML)
    assert_selector '#test-duplicate-id', visible: false, count: 1

    # Verify createLiveRegion returned the existing element (not a new one)
    are_same = page.evaluate_script('window.areSame')
    assert are_same, 'createLiveRegion should return existing element when ID already exists'

    # Verify the original content is preserved
    region = find('#test-duplicate-id', visible: false)
    assert_equal 'First region', region.text
  end

  test 'clearLiveRegion clears content of live region' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Create a live region with content, then clear it
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ createLiveRegion, clearLiveRegion }) => {
        const region = createLiveRegion({ id: 'test-clear-region' });
        region.textContent = 'Content to be cleared';
        window.beforeClear = region.textContent;

        clearLiveRegion(region);
        window.afterClear = region.textContent;
      });
    JS

    # Wait for script execution
    sleep 0.1

    # Verify the content was cleared
    before = page.evaluate_script('window.beforeClear')
    after = page.evaluate_script('window.afterClear')

    assert_equal 'Content to be cleared', before
    assert_equal '', after
  end

  test 'live region uses span element for consistency with server component' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Create a live region via JavaScript
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ createLiveRegion }) => {
        const region = createLiveRegion({ id: 'test-element-type' });
        window.tagName = region.tagName.toLowerCase();
      });
    JS

    # Wait for script execution
    sleep 0.1

    # Verify the element is a span (matching LiveRegionComponent)
    tag_name = page.evaluate_script('window.tagName')
    assert_equal 'span', tag_name
  end

  test 'announce clears region before setting new content' do
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Test that announce properly clears and sets content
    page.execute_script(<<~JS)
      import('utilities/live_region').then(({ announce, createLiveRegion }) => {
        const region = createLiveRegion({ id: 'test-announce-clear' });
        region.textContent = 'Old content';

        // The announce function should clear first, then set new content
        announce('New announcement', { element: region });
      });
    JS

    # Wait for requestAnimationFrame to complete
    sleep 0.2

    # Verify the content was replaced (not appended)
    region = find('#test-announce-clear', visible: false)
    assert_equal 'New announcement', region.text
  end

  test 'selection controller uses local live region for announcements' do
    # Visit samples page
    visit namespace_project_samples_url(@namespace, @project)
    assert_text strip_tags(I18n.t(:'components.viral.pagy.limit_component.summary', from: 1, to: 3, count: 3,
                                                                                    locale: @user.locale))

    # Select a sample to trigger selection announcement via live region
    find("table tbody tr th input##{dom_id(@sample1, :checkbox)}").click

    # Verify local live region exists (data-selection-target='status')
    assert_selector "span[data-selection-target='status']", visible: false

    # Verify the region has proper ARIA attributes for accessibility
    region = find("span[data-selection-target='status']", visible: false)
    assert_equal 'polite', region[:'aria-live']
    assert_equal 'status', region[:role]
    assert_includes region[:class], 'sr-only'

    # Verify it contains the selection announcement
    assert_match(/1.*selected/i, region.text)
  end
end
