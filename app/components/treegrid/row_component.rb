# frozen_string_literal: true

module Treegrid
  # Treegrid Row component
  class RowComponent < Component
    erb_template <<-ERB
      <%= tag.div(**@system_arguments) do %>
        <div role="gridcell" aria-colindex="1" style="display: contents;">
          <%= tag.button(**@button_arguments) do %>
            <%= pathogen_icon("caret-right", size: :sm) %>
          <% end %>
          <%= content %>
        </div>
      <% end %>
    ERB

    def initialize( # rubocop:disable Metrics/ParameterLists
      expanded: false,
      expandable: false,
      tabindex: -1,
      level: 1,
      posinset: 1,
      setsize: 1,
      button_arguments: {},
      **system_arguments
    )
      @button_arguments = button_arguments
      @system_arguments = system_arguments

      set_default_button_arguments(expanded, expandable)
      set_default_system_arguments(expanded, expandable, tabindex, level, posinset, setsize)
    end

    private

    def set_default_button_arguments(expanded, expandable)
      @button_arguments[:aria] ||= {}
      @button_arguments[:aria][:label] =
        expandable && expanded ? I18n.t(:'components.treegrid.row.collapse') : I18n.t(:'components.treegrid.row.expand')
      @button_arguments[:aria][:labelledby] = @system_arguments[:id]
      @button_arguments[:data] ||= {}
      @button_arguments[:data][:action] = 'click->treegrid#toggleRow'
      @button_arguments[:type] = 'button'
      @button_arguments[:class] = class_names(@button_arguments[:classes],
                                              'treegrid-row-toggle h-8 w-8 mt-2 cursor-pointer',
                                              'hover:bg-slate-100 dark:hover:bg-slate-600',
                                              'rounded-lg shrink-0 flex items-center justify-center dark:text-white')
      @button_arguments.delete(:classes)
      @button_arguments[:tabindex] = '-1'
    end

    def set_default_system_arguments(expanded, expandable, tabindex, level, posinset, setsize) # rubocop:disable Metrics/ParameterLists
      @system_arguments[:aria] = (@system_arguments[:aria] || {}).deep_merge({
                                                                               level: level,
                                                                               posinset: posinset,
                                                                               setsize: setsize
                                                                             })
      @system_arguments[:aria][:expanded] = expanded if expandable
      @system_arguments[:data] = {} unless @system_arguments.key?(:data)
      @system_arguments[:data]['treegrid-target'] = 'row'
      @system_arguments[:style] = "--treegrid-level: #{level};"
      @system_arguments[:class] =
        class_names(@system_arguments[:classes], 'treegrid-row rounded-lg flex py-2 px-2 overflow-hidden')
      @system_arguments.delete(:classes)
      @system_arguments[:role] = 'row'
      @system_arguments[:tabindex] = tabindex
    end
  end
end
