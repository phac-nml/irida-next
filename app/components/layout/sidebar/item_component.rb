# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar item component with modern styling and accessibility features
    #
    # @example Basic usage
    #   <%= render Layout::Sidebar::ItemComponent.new(
    #     url: root_path,
    #     label: 'Dashboard',
    #     icon: :house,
    #     selected: current_page?(root_path)
    #   ) %>
    #
    # @example With badge
    #   <%= render Layout::Sidebar::ItemComponent.new(
    #     url: notifications_path,
    #     label: 'Notifications',
    #     icon: :bell,
    #     badge: '3',
    #     selected: current_page?(notifications_path)
    #   ) %>
    class ItemComponent < Component
      # @!attribute [r] url
      #   @return [String, nil] the URL the item links to
      attr_reader :url

      # @!attribute [r] label
      #   @return [String] the display text for the item
      attr_reader :label

      # @!attribute [r] icon
      #   @return [Symbol, nil] the name of the icon to display
      attr_reader :icon

      # @!attribute [r] badge
      #   @return [String, Numeric, nil] optional badge to display next to the label
      attr_reader :badge

      # @!attribute [r] selected
      #   @return [Boolean] whether the item is in a selected/active state
      attr_reader :selected

      # @!attribute [r] system_arguments
      #   @return [Hash] additional HTML attributes to be included in the root element
      attr_reader :system_arguments

      # @!attribute [r] avatar
      #   @return [Boolean] whether to display an avatar next to the label
      attr_reader :avatar

      # Initialize a new Sidebar ItemComponent
      #
      # @param url [String, nil] the URL the item links to
      # @param label [String] the display text for the item
      # @param icon [Symbol, nil] the name of the icon to display (default: nil)
      # @param badge [String, Numeric, nil] optional badge to display next to the label (default: nil)
      # @param selected [Boolean] whether the item is in a selected/active state (default: false)
      # @param system_arguments [Hash] additional HTML attributes to be included in the root element
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        url:,
        label:,
        icon: nil,
        badge: nil,
        selected: false,
        avatar: false,
        **system_arguments
      )
        @url = url
        @label = label
        @icon = icon
        @badge = badge
        @selected = selected
        @avatar = avatar
        @system_arguments = system_arguments
      end
      # rubocop:enable Metrics/ParameterLists

      # Renders the icon with appropriate styling based on the item's state
      #
      # @return [ActiveSupport::SafeBuffer] the rendered icon HTML
      def create_icon
        return unless @icon

        icon_classes = class_names(
          'size-5 transition-colors duration-200',
          {
            'text-primary-800 dark:text-primary-400 fill-primary-800 dark:fill-primary-400' => selected,

            'text-slate-500 dark:text-slate-400 fill-slate-500 dark:fill-slate-400' => !selected,
            'group-hover/item:text-slate-600 dark:group-hover/item:text-slate-300' => !selected
          }
        )

        pathogen_icon(@icon, size: nil, color: nil, class: icon_classes, variant: :duotone)
      end
    end
  end
end
