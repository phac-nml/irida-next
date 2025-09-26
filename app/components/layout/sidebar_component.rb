# frozen_string_literal: true

module Layout
  # Sidebar component for navigation with collapsible sections and modern styling
  #
  # @example Basic usage
  #   <%= render Layout::SidebarComponent.new do |sidebar| %>
  #     <% sidebar.with_section(title: 'Main') do |section| %>
  #       <% section.with_item(url: root_path, selected: current_page?(root_path)) do |item| %>
  #         <% item.with_icon { pathogen_icon(:house) } %>
  #         Dashboard
  #       <% end %>
  #     <% end %>
  #   <% end %>
  class SidebarComponent < Component
    # @!attribute [r] pipelines_enabled
    #   @return [Boolean] whether pipelines are enabled in the application
    attr_reader :pipelines_enabled

    # @!attribute [r] collapsed_by_default
    #   @return [Boolean] whether the sidebar should start collapsed (default: false)
    attr_reader :collapsed_by_default

    renders_one :header, Sidebar::HeaderComponent
    renders_many :sections, Sidebar::SectionComponent
    renders_many :items, Sidebar::ItemComponent

    # Initialize a new SidebarComponent
    #
    # @param pipelines_enabled [Boolean] whether pipelines are enabled in the application
    # @param collapsed_by_default [Boolean] whether the sidebar should start collapsed (default: false)
    # @param system_arguments [Hash] additional HTML attributes to be included in the root element
    def initialize(pipelines_enabled: true, collapsed_by_default: false, **system_arguments)
      @pipelines_enabled = pipelines_enabled
      @collapsed_by_default = collapsed_by_default
      @system_arguments = system_arguments
      @system_arguments[:data] ||= {}
    end

    # Returns the CSS classes for the sidebar based on its state
    #
    # @return [String] the CSS classes
    def sidebar_classes
      class_names(
        'flex flex-col h-full text-sm bg-white/80 dark:bg-slate-900/80',
        'border-r border-slate-200/50 dark:border-slate-700/30',
        'backdrop-blur-sm transition-all duration-300 ease-in-out',
        @system_arguments[:class]
      )
    end
  end
end
