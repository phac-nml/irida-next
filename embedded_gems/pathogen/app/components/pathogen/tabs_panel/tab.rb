# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # This file defines the Pathogen::TabsPanel::Tab component, which handles each individual tab
    class Tab < Pathogen::Component
      TAG_DEFAULT = :a

      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

      renders_one :count, lambda { |**system_arguments|
        Pathogen::TabsPanel::Count.new(
          selected: @selected,
          **system_arguments
        )
      }

      # Renders a Phosphor icon for the tab
      # @param icon [Symbol, String] The name of the Phosphor icon to render
      # @param variant [Symbol] The variant of the icon (default: :regular, options: :regular, :thin, :light, :bold, :fill, :duotone)
      # @param size [String, Integer] The size of the icon (default: '1rem')
      # @param class [String] Additional CSS classes to apply to the icon
      renders_one :icon, ->(icon_name = nil, variant: :regular, size: '1rem', **system_arguments) do
        Pathogen::Icon.new(icon: icon_name, variant: variant, size: size, **system_arguments) if icon_name.present?
      end

      # rubocop:disable Metrics/ParameterLists
      # @param icon [Symbol, String] The name of the Phosphor icon to render (optional)
      # @param icon_variant [Symbol] The variant of the icon (default: :regular)
      # @param icon_size [String, Integer] The size of the icon (default: '1rem')
      def initialize(controls:, tab_type:, selected: false, text: '', wrapper_arguments: {}, icon: nil, icon_variant: :regular, icon_size: '1rem', **system_arguments)
        @controls = controls
        @selected = selected
        @text = text
        @tab_type = tab_type

        @system_arguments = system_arguments
        @wrapper_arguments = wrapper_arguments

        @system_arguments[:tag] = TAG_DEFAULT

        @wrapper_arguments[:tag] = :li
        @wrapper_arguments[:classes] = WRAPPER_CLASSES

        @system_arguments[:'aria-current'] = @selected ? 'page' : 'false'
        @system_arguments[:classes] = generate_tab_classes
        @system_arguments[:'aria-controls'] = @controls
        
        # Initialize icon if provided
        with_icon(icon, variant: icon_variant, size: icon_size) if icon.present?
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def generate_tab_classes
        if @tab_type == 'default'
          default_tab_classes
        elsif @tab_type == 'underline'
          underline_tab_classes
        end
      end

      def default_tab_classes
        if @selected
          'inline-block p-4 text-primary-600 bg-slate-100 rounded-t-lg active dark:bg-slate-800 dark:text-primary-500'
        else
          'inline-block p-4 rounded-t-lg hover:text-slate-600
        hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-slate-300'
        end
      end

      def underline_tab_classes
        if @selected
          'inline-block p-4 text-primary-600 border-b-2 border-primary-600
          rounded-t-lg active dark:text-primary-500 dark:border-primary-500'
        else
          'inline-block p-4 border-b-2 border-transparent rounded-t-lg
          hover:text-slate-600 hover:border-slate-300 dark:hover:text-slate-300'
        end
      end
    end
  end
end
