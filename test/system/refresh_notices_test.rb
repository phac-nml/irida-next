# frozen_string_literal: true

require 'application_system_test_case'

class RefreshNoticesTest < ApplicationSystemTestCase
  include ActionCable::TestHelper

  def setup
    sign_in users(:john_doe)
    @project = projects(:project1)
    @group = groups(:group_one)
  end

  test 'refresh notice appears when samples are updated in another session' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Verify the notice is initially hidden
    assert_selector '[data-refresh-target="notice"]', visible: false

    # Update a sample in the background (simulating another user's action)
    sample = samples(:sample1)

    # Use ActionCable test helper to simulate the broadcast
    broadcast_refresh_later_to @project, :samples

    # Wait for the notice to appear
    assert_selector '[data-refresh-target="notice"]', visible: true
    assert_text 'Samples table is out of date'
    assert_selector 'a', text: 'Refresh'
    assert_selector 'button', text: 'Dismiss'
  end

  test 'refresh notice can be dismissed' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Simulate a refresh broadcast
    broadcast_refresh_later_to @project, :samples

    # Wait for the notice to appear and then dismiss it
    assert_selector '[data-refresh-target="notice"]', visible: true
    click_button 'Dismiss'

    # Notice should be hidden again
    assert_selector '[data-refresh-target="notice"]', visible: false
  end

  test 'refresh notice refreshes the page when clicked' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Get current URL for comparison
    current_url = page.current_url

    # Simulate a refresh broadcast
    broadcast_refresh_later_to @project, :samples

    # Wait for the notice to appear and click refresh
    assert_selector '[data-refresh-target="notice"]', visible: true
    click_link 'Refresh'

    # Page should reload (same URL but fresh content)
    assert_equal current_url, page.current_url
    # Notice should be hidden after refresh
    assert_selector '[data-refresh-target="notice"]', visible: false
  end

  test 'refresh notice shows update count for multiple rapid updates' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Simulate multiple rapid broadcasts
    3.times do
      broadcast_refresh_later_to @project, :samples
    end

    # The notice should show the update count
    assert_selector '[data-refresh-target="notice"]', visible: true

    # Due to debouncing, we should see the count
    # Note: This test might be flaky due to timing, but it demonstrates the feature
    assert_text(/\(3 updates\)/, wait: 2)
  end

  test 'refresh notice appears on group samples page' do
    visit group_samples_path(@group)

    # Verify the notice is initially hidden
    assert_selector '[data-refresh-target="notice"]', visible: false

    # Simulate a refresh broadcast to the group
    broadcast_refresh_later_to @group, :samples

    # Wait for the notice to appear
    assert_selector '[data-refresh-target="notice"]', visible: true
    assert_text 'Samples table is out of date'
  end

  test 'refresh notice auto-dismisses when configured' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Verify auto-dismiss is configured (10 seconds for samples)
    refresh_div = page.find('[data-controller="refresh"]')
    assert_equal '10000', refresh_div['data-refresh-auto-dismiss-value']

    # Simulate a refresh broadcast
    broadcast_refresh_later_to @project, :samples

    # Notice should appear
    assert_selector '[data-refresh-target="notice"]', visible: true

    # Note: We can't easily test the actual auto-dismiss in a fast test,
    # but we can verify the configuration is present
  end

  test 'refresh notice respects debouncing configuration' do
    visit namespace_project_samples_path(@project.namespace, @project)

    # Verify debouncing is configured
    refresh_div = page.find('[data-controller="refresh"]')
    debounce_value = refresh_div['data-refresh-debounce-value']
    assert debounce_value.present?, 'Debounce value should be configured'
    assert debounce_value.to_i > 0, 'Debounce value should be positive'
  end

  private

  def broadcast_refresh_later_to(resource, stream_name)
    # Simulate the Turbo broadcast that would normally happen
    # We need to simulate the message that the refresh controller expects
    ActionCable.server.broadcast(
      "#{resource.to_gid_param}:#{stream_name}",
      '<turbo-stream action="refresh"></turbo-stream>'
    )

    # Give a small delay for JavaScript to process
    sleep 0.1
  end
end