# frozen_string_literal: true

module Pathogen
  # Tabs Component
  # Accessible tabs component following W3C ARIA Authoring Practices Guide.
  # Implements automatic tab activation with keyboard navigation support.
  #
  # @example Basic usage
  #   <%= render Pathogen::Tabs.new(id: "demo-tabs", label: "Content sections") do |tabs| %>
  #     <% tabs.with_tab(id: "tab-1", label: "Overview", selected: true) %>
  #     <% tabs.with_tab(id: "tab-2", label: "Details") %>
  #
  #     <% tabs.with_panel(id: "panel-1", tab_id: "tab-1") do %>
  #       <p>Overview content</p>
  #     <% end %>
  #
  #     <% tabs.with_panel(id: "panel-2", tab_id: "tab-2") do %>
  #       <p>Details content</p>
  #     <% end %>
  #   <% end %>
  #
  # @example With URL syncing for bookmarkable tabs
  #   <%= render Pathogen::Tabs.new(id: "demo-tabs", label: "Content sections", sync_url: true) do |tabs| %>
  #     <% tabs.with_tab(id: "tab-1", label: "Overview") %>
  #     <% tabs.with_tab(id: "tab-2", label: "Details") %>
  #
  #     <% tabs.with_panel(id: "panel-1", tab_id: "tab-1") do %>
  #       <p>Overview content</p>
  #     <% end %>
  #
  #     <% tabs.with_panel(id: "panel-2", tab_id: "tab-2") do %>
  #       <p>Details content</p>
  #     <% end %>
  #   <% end %>
  #
  # @example With Turbo Frame lazy loading
  #   <%= render Pathogen::Tabs.new(id: "demo-tabs", label: "Content sections") do |tabs| %>
  #     <% tabs.with_tab(id: "tab-1", label: "Overview") %>
  #     <% tabs.with_tab(id: "tab-2", label: "Details") %>
  #
  #     <% tabs.with_panel(id: "panel-1", tab_id: "tab-1") do %>
  #       <%= turbo_frame_tag "panel-1-content",
  #                           src: overview_path,
  #                           loading: :lazy do %>
  #         <%= render partial: "shared/loading/spinner" %>
  #       <% end %>
  #     <% end %>
  #
  #     <% tabs.with_panel(id: "panel-2", tab_id: "tab-2") do %>
  #       <%= turbo_frame_tag "panel-2-content",
  #                           src: details_path,
  #                           loading: :lazy do %>
  #         <%= render partial: "shared/loading/spinner" %>
  #       <% end %>
  #     <% end %>
  #   <% end %>
  class Tabs < Pathogen::Component
    # Orientation options for the tablist
    ORIENTATION_OPTIONS = %i[horizontal vertical].freeze
    ORIENTATION_DEFAULT = :horizontal

    # Renders individual tab controls
    # @param id [String] Unique identifier for the tab
    # @param label [String] Text label for the tab
    # @param selected [Boolean] Whether the tab is initially selected (default: false)
    # @param system_arguments [Hash] Additional HTML attributes
    # @return [Pathogen::Tabs::Tab] A new tab instance
    renders_many :tabs, lambda { |id:, label:, selected: false, **system_arguments|
      Pathogen::Tabs::Tab.new(
        id: id,
        label: label,
        selected: selected,
        **system_arguments
      )
    }

    # Renders tab panels
    # @param id [String] Unique identifier for the panel
    # @param tab_id [String] ID of the associated tab
    # @param system_arguments [Hash] Additional HTML attributes
    # @return [Pathogen::Tabs::TabPanel] A new panel instance
    renders_many :panels, lambda { |id:, tab_id:, **system_arguments, &block|
      Pathogen::Tabs::TabPanel.new(
        id: id,
        tab_id: tab_id,
        **system_arguments,
        &block
      )
    }

    # Renders optional content aligned to the right of the tabs
    renders_one :right_content

    # Initialize a new Tabs component
    # @param id [String] Unique identifier for the tablist (required)
    # @param label [String] Accessible label for the tablist (required)
    # @param default_index [Integer] Index of the initially selected tab (default: 0)
    # @param orientation [Symbol] Tab orientation (:horizontal or :vertical, default: :horizontal)
    # @param sync_url [Boolean] Whether to sync tab selection with URL hash for bookmarking (default: false)
    # @param system_arguments [Hash] Additional HTML attributes
    # @raise [ArgumentError] if id or label is missing
    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, label:, default_index: 0, orientation: ORIENTATION_DEFAULT, sync_url: false, **system_arguments)
      # rubocop:enable Metrics/ParameterLists
      raise ArgumentError, 'id is required' if id.blank?
      raise ArgumentError, 'label is required' if label.blank?

      @id = id
      @label = label
      @default_index = default_index
      @orientation = fetch_or_fallback(ORIENTATION_OPTIONS, orientation, ORIENTATION_DEFAULT)
      @sync_url = sync_url
      @system_arguments = system_arguments

      setup_container_attributes
    end

    # Validates component configuration before rendering
    # @raise [ArgumentError] if validation fails
    def before_render_check
      validate_tabs_and_panels!
      validate_default_index!
      validate_unique_ids!
      validate_panel_associations!
    end

    private

    # Sets up HTML attributes for the container element
    def setup_container_attributes
      @system_arguments[:id] = @id
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'pathogen--tabs'
      @system_arguments[:data]['pathogen--tabs-default-index-value'] = @default_index
      @system_arguments[:data]['pathogen--tabs-sync-url-value'] = @sync_url
    end

    # Validates that tabs and panels are properly configured
    # @raise [ArgumentError] if validation fails
    def validate_tabs_and_panels!
      raise ArgumentError, 'At least one tab is required' if tabs.empty?
      raise ArgumentError, 'At least one panel is required' if panels.empty?
      raise ArgumentError, 'Tab and panel counts must match' if tabs.count != panels.count
    end

    # Validates the default_index parameter
    # @raise [ArgumentError] if default_index is out of bounds
    def validate_default_index!
      return if @default_index >= 0 && @default_index < tabs.count

      raise ArgumentError, "default_index #{@default_index} out of bounds (#{tabs.count} tabs)"
    end

    # Validates that all tab and panel IDs are unique
    # @raise [ArgumentError] if duplicate IDs are found
    def validate_unique_ids!
      tab_ids = tabs.map(&:id)
      raise ArgumentError, 'Duplicate tab IDs found' if tab_ids.uniq.length != tab_ids.length

      panel_ids = panels.map(&:id)
      return unless panel_ids.uniq.length != panel_ids.length

      raise ArgumentError, 'Duplicate panel IDs found'
    end

    # Validates that all panels reference existing tabs
    # @raise [ArgumentError] if a panel references a non-existent tab
    def validate_panel_associations!
      tab_ids = tabs.map(&:id)
      panels.each do |panel|
        unless tab_ids.include?(panel.tab_id)
          raise ArgumentError, "Panel #{panel.id} references non-existent tab #{panel.tab_id}"
        end
      end
    end
  end
end
