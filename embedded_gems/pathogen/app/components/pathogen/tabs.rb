# frozen_string_literal: true

module Pathogen
  # Tabs Component
  # Accessible tabs component following W3C ARIA Authoring Practices Guide.
  # Implements automatic tab activation with keyboard navigation support.
  #
  # == CSS Dependencies
  #
  # This component requires the following CSS to be present in your application:
  #
  # 1. **Tailwind 'hidden' class** (or equivalent):
  #    .hidden { display: none; }
  #
  # 2. **Tab panel visibility rules** (see app/assets/tailwind/application.css):
  #    - Progressive enhancement for non-JS environments
  #    - Visibility control for active panels
  #    - Dynamic tab styling based on aria-selected
  #
  # 3. **JavaScript controller**: app/javascript/controllers/pathogen/tabs_controller.js
  #    - Handles ARIA state management
  #    - Keyboard navigation (Arrow keys, Home, End)
  #    - Optional URL hash syncing
  #    - Turbo Frame lazy loading integration
  #
  # @see app/assets/tailwind/application.css for required CSS rules
  # @see app/javascript/controllers/pathogen/tabs_controller.js for controller implementation
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
  #
  # @example With LazyPanel for conditional lazy loading (recommended)
  #   <%= render Pathogen::Tabs.new(id: "demo-tabs", label: "Content sections") do |tabs| %>
  #     <% tabs.with_tab(id: "tab-1", label: "Overview", selected: @tab == "overview") %>
  #     <% tabs.with_tab(id: "tab-2", label: "Details", selected: @tab == "details") %>
  #
  #     <% tabs.with_lazy_panel(
  #       id: "panel-1",
  #       tab_id: "tab-1",
  #       frame_id: "overview-content",
  #       src_path: overview_path(@resource),
  #       selected: @tab == "overview"
  #     ) do %>
  #       <%= render partial: "overview" %>
  #     <% end %>
  #
  #     <% tabs.with_lazy_panel(
  #       id: "panel-2",
  #       tab_id: "tab-2",
  #       frame_id: "details-content",
  #       src_path: details_path(@resource),
  #       selected: @tab == "details"
  #     ) do %>
  #       <%= render partial: "details" %>
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
        orientation: @orientation,
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

    # Renders tab panels with conditional Turbo Frame lazy loading
    # Simplifies the pattern of conditionally rendering eager/lazy turbo frames
    # @param id [String] Unique identifier for the panel
    # @param tab_id [String] ID of the associated tab
    # @param frame_id [String] Unique identifier for the turbo frame
    # @param src_path [String] URL to lazy-load content from
    # @param selected [Boolean] Whether this is the currently active tab
    # @param refresh [String] Turbo refresh strategy (default: \"morph\")
    # @param system_arguments [Hash] Additional HTML attributes
    # @return [Pathogen::Tabs::TabPanel] A new panel instance wrapping LazyPanel
    renders_many :lazy_panels,
                 lambda { |id:, tab_id:, frame_id:, src_path:, selected:, refresh: 'morph', **system_arguments, &block|
                   lazy_panel_instance = Pathogen::Tabs::LazyPanel.new(
                     frame_id: frame_id,
                     src_path: src_path,
                     selected: selected,
                     refresh: refresh
                   )

                   Pathogen::Tabs::TabPanel.new(
                     id: id,
                     tab_id: tab_id,
                     lazy_panel: lazy_panel_instance,
                     **system_arguments,
                     &block
                   )
                 }

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
    # ViewComponent lifecycle hook called automatically before rendering
    # @raise [ArgumentError] if validation fails
    def before_render
      validate_tabs_and_panels!
      validate_default_index!
      validate_unique_ids!
      validate_panel_associations!
      apply_initial_panel_visibility
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

      total_panels = panels.count + lazy_panels.count
      raise ArgumentError, 'At least one panel is required' if total_panels.zero?
      raise ArgumentError, 'Tab and panel counts must match' if tabs.count != total_panels
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

      all_panel_ids = panels.map(&:id) + lazy_panels.map(&:id)
      return unless all_panel_ids.uniq.length != all_panel_ids.length

      raise ArgumentError, 'Duplicate panel IDs found'
    end

    # Validates that all panels reference existing tabs
    # @raise [ArgumentError] if a panel references a non-existent tab
    def validate_panel_associations!
      tab_ids = tabs.map(&:id)
      all_panels = panels + lazy_panels
      all_panels.each do |panel|
        unless tab_ids.include?(panel.tab_id)
          raise ArgumentError, "Panel #{panel.id} references non-existent tab #{panel.tab_id}"
        end
      end
    end

    def apply_initial_panel_visibility
      all_panels = panels + lazy_panels
      all_panels.each_with_index do |panel, index|
        panel.set_initial_visibility(hidden: index != @default_index)
      end
    end
  end
end
