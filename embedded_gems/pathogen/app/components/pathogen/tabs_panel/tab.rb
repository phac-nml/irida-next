# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # 🎯 Tab Component
    # Individual tab element with proper ARIA attributes and keyboard navigation
    class Tab < Pathogen::Component
      TAG_DEFAULT = :a
      TAG_OPTIONS = [TAG_DEFAULT, :button].freeze

      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

      # 📝 Renders count badge for the tab
      renders_one :count, lambda { |**system_arguments|
        Pathogen::TabsPanel::Count.new(
          selected: @selected,
          **system_arguments
        )
      }

      # 🎨 Renders icon for the tab
      renders_one :icon, Pathogen::Icon

      # 🚀 Initialize a new Tab component
      # @param options [Hash] Configuration options for the tab
      # @option options [String] :controls ID of the controlled tab panel
      # @option options [String] :tab_type Visual style of the tab
      # @option options [Boolean] :selected Whether the tab is selected
      # @option options [String] :text Text content of the tab
      # @option options [String] :href URL for the tab link (optional)
      # @option options [Hash] :wrapper_arguments Additional arguments for the wrapper
      # @option options [Hash] :system_arguments Additional system arguments
      def initialize(options = {})
        @id = options[:id]
        @controls = options[:controls]
        @selected = options[:selected] || false
        @text = options[:text] || ''
        @tab_type = options[:tab_type]
        @href = options[:href]

        @system_arguments = options[:system_arguments] || {}
        @wrapper_arguments = options[:wrapper_arguments] || {}

        setup_tab_attributes
        setup_wrapper_attributes
        setup_visual_styling
      end

      private

      def setup_tab_attributes
        @system_arguments[:tag] = @href ? TAG_DEFAULT : :button
        @system_arguments[:role] = 'tab'
        @system_arguments[:'aria-selected'] = @selected
        @system_arguments[:'aria-controls'] = @controls
        @system_arguments[:href] = @href if @href
        @system_arguments[:type] = 'button' if @system_arguments[:tag] == :button
        @system_arguments[:data] = {
          turbo_action: 'replace'
        }
      end

      def setup_wrapper_attributes
        @wrapper_arguments[:tag] = :li
        @wrapper_arguments[:classes] = WRAPPER_CLASSES
        @wrapper_arguments[:role] = 'presentation'
      end

      def setup_visual_styling
        @system_arguments[:classes] = generate_tab_classes
      end

      # 🎨 Generate appropriate classes based on tab type and state
      def generate_tab_classes
        if @tab_type == 'default'
          default_tab_classes
        elsif @tab_type == 'underline'
          underline_tab_classes
        end
      end

      # 💅 Default tab style classes (accessible, not primary color for selected)
      # 💅 Base tab classes shared between styles
      def base_tab_classes
        'inline-block p-4 rounded-t-lg'
      end

      def default_tab_classes
        base = base_tab_classes
        if @selected
          "#{base} bg-slate-100 text-slate-900 dark:bg-slate-800 dark:text-slate-100 " \
            'hover:bg-slate-50 hover:text-slate-900 dark:hover:bg-slate-700 dark:hover:text-slate-100'
        else
          "#{base} text-slate-600 hover:text-slate-900 hover:bg-slate-50 " \
            'dark:text-slate-300 dark:hover:text-slate-100 dark:hover:bg-slate-700'
        end
      end

      # 💅 Underline tab style classes (accessible, not primary color for selected)
      def underline_tab_classes
        base = base_tab_classes
        if @selected
          "#{base} border-b-2 border-slate-900 bg-slate-100 text-slate-900 " \
            'dark:border-slate-100 dark:bg-slate-800 dark:text-slate-100 ' \
            'hover:bg-slate-50 hover:text-slate-900 dark:hover:bg-slate-700 dark:hover:text-slate-100'
        else
          "#{base} border-b-2 border-transparent text-slate-600 " \
            'hover:text-slate-900 hover:border-slate-400 hover:bg-slate-50 ' \
            'dark:text-slate-300 dark:hover:text-slate-100 dark:hover:border-slate-100 ' \
            'dark:hover:bg-slate-700'
        end
      end
    end
  end
end
