# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # 🎯 Tab Component
    # A navigation link component that supports Turbo Drive integration
    # and dynamic content updates with proper styling and accessibility.
    #
    # @example Basic usage with text
    #   <%= render Pathogen::TabsPanel::Tab.new(
    #     id: "nav-1",
    #     text: "Home",
    #     href: "/home",
    #     selected: true
    #   ) %>
    #
    # @example With icon and count badge
    #   <%= render Pathogen::TabsPanel::Tab.new(
    #     id: "nav-2",
    #     text: "Notifications",
    #     href: "/notifications"
    #   ) do |tab| %>
    #     <%= tab.with_icon(icon: "bell") %>
    #     <%= tab.with_count(count: 5) %>
    #   <% end %>
    # rubocop:disable Metrics/ClassLength
    class Tab < Pathogen::Component
      # 🔧 Constants
      TAG_DEFAULT = :a
      TAG_OPTIONS = [TAG_DEFAULT, :button].freeze
      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

      # 📝 Renders a count badge for the tab
      # @param count [Integer] The count to display
      # @param system_arguments [Hash] Additional arguments for the count component
      # @return [Pathogen::TabsPanel::Count] The count component instance
      renders_one :count, lambda { |count: nil, **system_arguments|
        @count = count
        Pathogen::TabsPanel::Count.new(
          count: count,
          selected: @selected,
          **system_arguments
        )
      }

      # 🎨 Renders an icon for the tab
      # @param icon [String] The icon name to render
      # @return [Pathogen::Icon] The icon component instance
      renders_one :icon, lambda { |icon: nil|
        @icon = icon
        Pathogen::Icon.new(icon, size: :sm, class: 'mr-1.5')
      }

      # 🚀 Initialize a new Tab component
      # @param options [Hash] Configuration options for the tab
      # @option options [String] :id Unique identifier for the tab
      # @option options [Boolean] :selected Whether the tab is selected
      # @option options [String] :text Text content of the tab (required)
      # @option options [String] :href URL for the tab link
      # @option options [Hash] :wrapper_arguments Additional arguments for the wrapper
      # @option options [Hash] :system_arguments Additional system arguments
      # @raise [ArgumentError] If required options are missing
      def initialize(options = {})
        @id = options[:id]
        @selected = options[:selected] || false
        @text = options[:text].to_s
        @href = options[:href]
        @count = nil
        @icon = nil

        validate_required_options!
        setup_arguments(options)
        setup_attributes
      end

      private

      # 🔍 Validates that all required options are present
      # @raise [ArgumentError] If any required options are missing
      def validate_required_options!
        required_options = { href: @href, id: @id, text: @text }
        missing_options = required_options.select { |_, value| value.blank? }

        return if missing_options.empty?

        raise ArgumentError, "Missing required options: #{missing_options.keys.join(', ')}"
      end

      # 🏗️ Sets up component arguments
      # @param options [Hash] The options hash containing system and wrapper arguments
      def setup_arguments(options)
        @system_arguments = options[:system_arguments] || {}
        @wrapper_arguments = options[:wrapper_arguments] || {}
      end

      # 🏗️ Sets up all component attributes
      def setup_attributes
        setup_link_attributes
        setup_wrapper_attributes
        setup_visual_styling
      end

      # 🏗️ Sets up link-specific attributes and data
      def setup_link_attributes
        @system_arguments.merge!(
          tag: TAG_DEFAULT,
          id: @id,
          href: @href,
          'aria-current': @selected ? 'page' : nil,
          data: {
            turbo_action: 'replace',
            tabs_target: 'link'
          }
        )
      end

      # 🏗️ Sets up wrapper element attributes
      def setup_wrapper_attributes
        @wrapper_arguments[:tag] ||= :li
        @wrapper_arguments[:classes] ||= WRAPPER_CLASSES
      end

      # 🏗️ Sets up visual styling classes
      def setup_visual_styling
        @system_arguments[:classes] = generate_tab_classes
      end

      # 🎨 Generates appropriate classes based on tab state
      # @return [String] The generated CSS classes
      def generate_tab_classes
        underline_tab_classes
      end

      # 💅 Base tab classes shared between styles
      # @return [String] The base CSS classes
      def base_tab_classes
        [
          'inline-block p-4 rounded-t-lg',
          'font-semibold transition-colors',
          'duration-200 ease-in-out'
        ].join(' ')
      end

      # 💅 Underline tab style classes
      # @return [String] The underline tab CSS classes
      def underline_tab_classes
        base = base_tab_classes
        @selected ? selected_tab_classes(base) : unselected_tab_classes(base)
      end

      # 💅 Selected tab style classes
      # @param base [String] Base classes to extend
      # @return [String] The selected tab CSS classes
      def selected_tab_classes(base)
        [
          base,
          'border-b-2 border-primary-800',
          'text-slate-900 rounded-t-lg',
          'active bg-transparent',
          'dark:border-white dark:text-white'
        ].join(' ')
      end

      # 💅 Unselected tab style classes
      # @param base [String] Base classes to extend
      # @return [String] The unselected tab CSS classes
      def unselected_tab_classes(base)
        [
          base,
          'border-b-2 border-transparent',
          'text-slate-700 hover:text-slate-900',
          'hover:border-slate-700 rounded-t-lg',
          'dark:text-slate-200 dark:hover:text-white',
          'dark:hover:border-white'
        ].join(' ')
      end

      # Move ARIA label generation to render time
      def call
        @system_arguments[:'aria-label'] = generate_aria_label
        super
      end

      # 🏷️ Generates an accessible label for the tab
      # @return [String] The generated ARIA label
      def generate_aria_label
        parts = [@text]
        parts << "with #{@count} items" if @count.present?
        parts.join(', ')
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
