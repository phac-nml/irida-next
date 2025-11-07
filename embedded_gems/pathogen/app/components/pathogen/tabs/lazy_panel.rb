# frozen_string_literal: true

module Pathogen
  class Tabs
    # LazyPanel Component
    # Wraps TabPanel with conditional Turbo Frame lazy loading.
    # Renders content immediately if selected, otherwise defers loading.
    #
    # This component simplifies the common pattern of conditionally rendering
    # turbo_frame_tag with either eager content or lazy loading attributes.
    #
    # @example Basic usage with lazy loading
    #   <%= render Pathogen::Tabs.new(id: "demo-tabs", label: "Content") do |tabs| %>
    #     <% tabs.with_tab(id: "tab-1", label: "Overview", selected: true) %>
    #     <% tabs.with_tab(id: "tab-2", label: "Details") %>
    #
    #     <% tabs.with_lazy_panel(
    #       id: "panel-1",
    #       tab_id: "tab-1",
    #       frame_id: "overview-content",
    #       src_path: overview_path,
    #       selected: true
    #     ) do %>
    #       <%= render partial: "overview" %>
    #     <% end %>
    #
    #     <% tabs.with_lazy_panel(
    #       id: "panel-2",
    #       tab_id: "tab-2",
    #       frame_id: "details-content",
    #       src_path: details_path,
    #       selected: false
    #     ) do %>
    #       <%= render partial: "details" %>
    #     <% end %>
    #   <% end %>
    #
    # == How It Works
    #
    # When `selected: true`:
    #   - Renders TabPanel containing turbo_frame_tag with content block
    #   - Content is rendered immediately (eager loading)
    #
    # When `selected: false`:
    #   - Renders TabPanel containing empty turbo_frame_tag with src, loading, refresh
    #   - Content is loaded lazily when panel becomes visible
    #
    # The Stimulus controller removes the `hidden` class when tab is selected,
    # triggering Turbo to fetch the frame content automatically.
    class LazyPanel < Pathogen::Component
      attr_reader :frame_id, :src_path, :selected, :refresh

      # Initialize a new LazyPanel component
      # @param frame_id [String] Unique identifier for the turbo frame (required)
      # @param src_path [String] URL to lazy-load content from (required)
      # @param selected [Boolean] Whether this is the currently active tab (required)
      # @param refresh [String] Turbo refresh strategy (default: "morph")
      # @param system_arguments [Hash] Additional HTML attributes passed to turbo_frame_tag
      # Content block is automatically captured by ViewComponent and available via `content` helper
      def initialize(frame_id:, src_path:, selected:, refresh: 'morph', **system_arguments)
        raise ArgumentError, 'frame_id is required' if frame_id.blank?
        raise ArgumentError, 'src_path is required' if src_path.blank?
        raise ArgumentError, 'selected must be a boolean' unless [true, false].include?(selected)

        @frame_id = frame_id
        @src_path = src_path
        @selected = selected
        @refresh = refresh
        @system_arguments = system_arguments
      end

      # Whether to render content immediately (eager) or defer (lazy)
      # @return [Boolean] true if selected, false otherwise
      def render_eager?
        @selected
      end
    end
  end
end
