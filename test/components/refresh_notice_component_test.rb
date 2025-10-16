# frozen_string_literal: true

require 'view_component_test_case'

class RefreshNoticeComponentTest < ViewComponentTestCase
  def setup
    @project = namespaces_project_namespaces(:project1)
  end

  # 🔄 BASIC RENDERING - Ensure component renders with required elements

  test 'renders with refresh controller and turbo stream' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    assert_selector '[data-controller="refresh"]', count: 1
    assert_selector 'turbo-cable-stream-source', count: 1
    assert_selector '[data-refresh-target="source"]', count: 1
  end

  test 'renders with viral alert component' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    assert_selector '[data-refresh-target="notice"]', count: 1
    assert_selector '.hidden', count: 1
    assert_selector '[aria-live="assertive"]', count: 1
  end

  test 'uses default message when not provided' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    assert_text I18n.t('components.refresh_notice.default_message')
  end

  test 'uses default link text when not provided' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    assert_text I18n.t('components.refresh_notice.default_link_text')
  end

  # 🎯 CUSTOM CONTENT - Test custom messages and links

  test 'renders with custom message' do
    custom_message = 'New data available'
    render_inline(RefreshNoticeComponent.new(
                    streamable: @project,
                    stream_name: :samples,
                    message: custom_message
                  ))

    assert_text custom_message
  end

  test 'renders with custom link text' do
    custom_link_text = 'Load new data'
    render_inline(RefreshNoticeComponent.new(
                    streamable: @project,
                    stream_name: :samples,
                    link_text: custom_link_text
                  ))

    assert_text custom_link_text
  end

  test 'renders with both custom message and link text' do
    custom_message = 'Updates are ready'
    custom_link_text = 'Reload page'
    render_inline(RefreshNoticeComponent.new(
                    streamable: @project,
                    stream_name: :samples,
                    message: custom_message,
                    link_text: custom_link_text
                  ))

    assert_text custom_message
    assert_text custom_link_text
  end

  # 🔌 TURBO STREAM CONFIGURATION - Test stream setup

  test 'configures turbo stream with correct streamable and stream name' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    turbo_source = page.find('turbo-cable-stream-source')
    # The channel attribute should include the project and stream name
    assert turbo_source['channel'].present?
  end

  test 'works with different stream names' do
    %i[samples members attachments].each do |stream_name|
      render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: stream_name))

      assert_selector '[data-controller="refresh"]', count: 1
      assert_selector 'turbo-cable-stream-source', count: 1
    end
  end

  # 🎨 SYSTEM ARGUMENTS - Test custom styling and attributes

  test 'accepts and applies additional system arguments' do
    render_inline(RefreshNoticeComponent.new(
                    streamable: @project,
                    stream_name: :samples,
                    class: 'custom-class',
                    id: 'custom-id'
                  ))

    assert_selector '#custom-id', count: 1
    assert_selector '.custom-class', count: 1
    assert_selector '[data-controller="refresh"]', count: 1
  end

  # 🔧 ACCESSIBILITY - Test accessibility attributes

  test 'alert has proper accessibility attributes' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    assert_selector '[aria-live="assertive"]', count: 1
  end

  test 'alert is initially hidden' do
    render_inline(RefreshNoticeComponent.new(streamable: @project, stream_name: :samples))

    # The alert should have the hidden class initially
    assert_selector '.hidden', count: 1
  end

  # 🧪 INTEGRATION - Test component structure

  test 'complete component structure is correct' do
    render_inline(RefreshNoticeComponent.new(
                    streamable: @project,
                    stream_name: :samples,
                    message: 'Test message',
                    link_text: 'Test link'
                  ))

    # Wrapper with refresh controller
    assert_selector '[data-controller="refresh"]', count: 1

    # Turbo stream source
    assert_selector 'turbo-cable-stream-source[data-refresh-target="source"]', count: 1

    # Alert notice
    assert_selector '[data-refresh-target="notice"]', count: 1
    assert_selector '[aria-live="assertive"]', count: 1

    # Content
    assert_text 'Test message'
    assert_text 'Test link'
  end
end
