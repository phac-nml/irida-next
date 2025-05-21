# frozen_string_literal: true

module Layout
  module Sidebar
    # Sidebar multi-level menu component with collapsible submenus
    #
    # @example Basic usage
    #   <%= render Layout::Sidebar::MultiLevelMenuComponent.new(
    #     title: 'Projects',
    #     icon: :folder,
    #     selectable_pages: [projects_path, new_project_path],
    #     current_page: request.path
    #   ) do |menu| %>
    #     <% menu.with_menu_item(url: projects_path, selected: current_page?(projects_path)) do |item| %>
    #       <% item.with_icon { helpers.render_icon(:squares_four) } %>
    #       All Projects
    #     <% end %>
    #     <% menu.with_menu_item(url: new_project_path, selected: current_page?(new_project_path)) do |item| %>
    #       <% item.with_icon { helpers.render_icon(:plus) } %>
    #       New Project
    #     <% end %>
    #   <% end %>
    class MultiLevelMenuComponent < Component
      # @!attribute [r] title
      #   @return [String] the title of the menu
      attr_reader :title

      # @!attribute [r] selectable_pages
      #   @return [Array<String>] array of paths that should trigger the menu to appear selected
      attr_reader :selectable_pages

      # @!attribute [r] current_page
      #   @return [String] the current page path for comparison
      attr_reader :current_page

      # @!attribute [r] icon
      #   @return [Symbol, nil] the name of the icon to display
      attr_reader :icon

      # @!attribute [r] selected
      #   @return [Boolean] whether the menu is in a selected/active state
      attr_reader :selected

      renders_many :menu_items, ItemComponent

      # Initialize a new MultiLevelMenuComponent
      #
      # @param title [String] the title of the menu
      # @param icon [Symbol, nil] the name of the icon to display (default: nil)
      # @param selectable_pages [Array<String>] array of paths that should trigger the menu to appear selected
      # @param current_page [String] the current page path for comparison
      # @param system_arguments [Hash] additional HTML attributes to be included in the root element
      def initialize(
        title: nil,
        icon: nil,
        selectable_pages: [],
        current_page: nil,
        **system_arguments
      )
        @title = title
        @icon = icon
        @selectable_pages = selectable_pages
        @current_page = current_page
        @selected = selectable_pages.include?(current_page)
        @system_arguments = system_arguments
      end

      # Renders the icon with appropriate styling based on the menu's state
      #
      # @return [ActiveSupport::SafeBuffer, nil] the rendered icon HTML or nil if no icon is set
      def create_icon
        return unless @icon

        icon_classes = class_names(
          'size-5 transition-colors duration-200',
          {
            'text-primary-800 dark:text-primary-400' => @selected,

            'text-slate-500 dark:text-slate-400 ' \
            'group-hover/menu:text-slate-600 dark:group-hover/menu:text-slate-300' => !@selected
          }
        )

        # Only set variant for non-selected items to use duotone
        variant = @selected ? nil : :duotone

        helpers.render_icon(@icon, class: icon_classes, variant: variant)
      end

      # Determines if the menu should be expanded by default
      #
      # @return [Boolean] whether the menu should be expanded
      def expanded_by_default?
        @selected
      end

      # Generates a unique ID for the menu's collapsible section
      #
      # @return [String] a unique identifier for the menu
      def menu_id
        @menu_id ||= "menu-#{SecureRandom.hex(4)}"
      end
    end
  end
end
