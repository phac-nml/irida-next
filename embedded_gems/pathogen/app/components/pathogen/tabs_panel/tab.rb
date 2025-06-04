# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # 🎯 Tab Component
    # Individual tab element with proper ARIA attributes and keyboard navigation.
    # Uses Turbo Drive for full page navigation with morphing.
    #
    # @example Basic usage
    #   <%= render Pathogen::TabsPanel::Tab.new(
    #     id: "tab-1",
    #     controls: "panel-1",
    #     tablist_id: "tabs",
    #     text: "Home",
    #     href: "/home",
    #     selected: true
    #   ) %>
    #
    # @example With count badge
    #   <%= render Pathogen::TabsPanel::Tab.new(...) do |tab| %>
    #     <%= tab.count { "5" } %>
    #   <% end %>
    class Tab < Pathogen::Component
      TAG_DEFAULT = :a
      TAG_OPTIONS = [TAG_DEFAULT, :button].freeze
      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

      # 📝 Renders count badge for the tab
      # @param system_arguments [Hash] Additional arguments for the count component
      # @return [Pathogen::TabsPanel::Count] The count component
      renders_one :count, lambda { |**system_arguments|
        Pathogen::TabsPanel::Count.new(
          selected: @selected,
          **system_arguments
        )
      }

      # 🎨 Renders icon for the tab
      # @return [Pathogen::Icon] The icon component
      renders_one :icon, lambda { |icon: nil|
        Pathogen::Icon.new(icon: icon, classes: 'size-4 mr-1.5')
      }

      # 🚀 Initialize a new Tab component
      # @param options [Hash] Configuration options for the tab
      # @option options [String] :id Unique identifier for the tab
      # @option options [String] :controls ID of the controlled tab panel
      # @option options [String] :tablist_id ID of the tablist element
      # @option options [Boolean] :selected Whether the tab is selected
      # @option options [String] :text Text content of the tab
      # @option options [String] :href URL for the tab link
      # @option options [Hash] :wrapper_arguments Additional arguments for the wrapper
      # @option options [Hash] :system_arguments Additional system arguments
      # @raise [ArgumentError] If required options are missing
      def initialize(options = {})
        @id = options[:id]
        @controls = options[:controls]
        @tablist_id = options[:tablist_id]
        @selected = options[:selected] || false
        @text = options[:text].to_s
        @href = options[:href]

        validate_required_options!
        setup_arguments(options)
        setup_attributes
      end

      private

      def validate_required_options!
        required_options = { href: @href, id: @id, controls: @controls, tablist_id: @tablist_id }
        missing_options = required_options.select { |_, value| value.nil? }

        return if missing_options.empty?

        raise ArgumentError, "Missing required options: #{missing_options.keys.join(', ')}"
      end

      def setup_arguments(options)
        @system_arguments = options[:system_arguments] || {}
        @wrapper_arguments = options[:wrapper_arguments] || {}
      end

      def setup_attributes
        setup_tab_attributes
        setup_wrapper_attributes
        setup_visual_styling
      end

      def setup_tab_attributes
        @system_arguments.merge!(
          tag: TAG_DEFAULT,
          role: 'tab',
          id: @id,
          'aria-selected': @selected,
          'aria-controls': @controls,
          href: @href,
          data: { turbo_action: 'replace' }
        )
      end

      def setup_wrapper_attributes
        @wrapper_arguments.merge!(
          tag: :li,
          classes: WRAPPER_CLASSES,
          role: 'presentation'
        )
      end

      def setup_visual_styling
        @system_arguments[:classes] = generate_tab_classes
      end

      # 🎨 Generate appropriate classes based on tab state
      # @return [String] The generated CSS classes
      def generate_tab_classes
        underline_tab_classes
      end

      # 💅 Base tab classes shared between styles
      # @return [String] The base CSS classes
      def base_tab_classes
        'inline-block p-4 rounded-t-lg font-semibold transition-colors duration-200 ease-in-out'
      end

      # 💅 Underline tab style classes
      # @return [String] The underline tab CSS classes
      def underline_tab_classes
        base = base_tab_classes
        if @selected
          "#{base} border-b-2 border-primary-800 text-slate-900 rounded-t-lg active bg-transparent " \
            'dark:border-white dark:text-white'
        else
          "#{base} border-b-2 border-transparent text-slate-700 hover:text-slate-900 " \
            'hover:border-slate-700 rounded-t-lg dark:text-slate-200 dark:hover:text-white ' \
            'dark:hover:border-white'
        end
      end
    end
  end
end
