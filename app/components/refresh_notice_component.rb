# frozen_string_literal: true

# ViewComponent for refresh notifications with Turbo Streams.
#
# Responsibilities
# - Render a hidden alert that shows when a page has been updated via Turbo Streams
# - Integrate with the "refresh" Stimulus controller
# - Provide a link to refresh the page content
#
# Usage
#   <%= render RefreshNoticeComponent.new(
#     streamable: @project,
#     stream_name: :samples
#   ) %>
#
#   # With custom messages
#   <%= render RefreshNoticeComponent.new(
#     streamable: @project,
#     stream_name: :samples,
#     message: "New data available",
#     link_text: "Load new data"
#   ) %>
#
# Notes
# - The component uses the "refresh" Stimulus controller to manage visibility
# - The alert is initially hidden and shown when Turbo Stream updates are received
class RefreshNoticeComponent < Component
  # @return [Object] The streamable object (e.g., @project)
  attr_reader :streamable
  # @return [Symbol, String] The stream name (e.g., :samples)
  attr_reader :stream_name
  # @return [String] The message to display in the alert
  attr_reader :message
  # @return [String] The text for the refresh link
  attr_reader :link_text

  # Initialize the RefreshNotice component.
  #
  # @param streamable [Object] The object to establish a Turbo Stream connection from
  # @param stream_name [Symbol, String] The name of the stream (e.g., :samples, :members)
  # @param message [String] The message to display when an update is available
  # @param link_text [String] The text for the refresh link
  # @param system_arguments [Hash] Additional HTML attributes (classes are merged)
  def initialize(streamable:, stream_name:, message: nil, link_text: nil, **system_arguments)
    super()
    @streamable = streamable
    @stream_name = stream_name
    @message = message || I18n.t('components.refresh_notice.default_message')
    @link_text = link_text || I18n.t('components.refresh_notice.default_link_text')
    @system_arguments = system_arguments
    @system_arguments[:data] ||= {}
    @system_arguments[:data][:controller] = 'refresh'
    @system_arguments[:data][:action] ||= ''
  end

  # Compose safe HTML attributes for the outer wrapper.
  #
  # @return [Hash] merged attributes suitable for tag helpers
  def system_arguments_with_data
    @system_arguments
  end

  # Unique ID for the alert
  #
  # @return [String]
  def alert_id
    @alert_id ||= "refresh-notice-#{object_id}"
  end

  # Whether to show the notice UI (vs. auto-refreshing)
  #
  # @return [Boolean]
  def show_notice?
    Flipper.enabled?(:samples_refresh_notice)
  end
end
