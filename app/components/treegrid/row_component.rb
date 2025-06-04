# frozen_string_literal: true

module Treegrid
  # Treegrid Row component
  class RowComponent < Component
    erb_template <<-ERB
      <%= tag.div(**@system_arguments) do %>
        <div role="gridcell" aria-colindex="1">
          <button class="treegrid-row-toggle" type="button" tabindex="-1" data-action="click->treegrid#toggleRow">
            <%= viral_icon(name: "chevron_right", classes: "size-4") %>
          </button>
          <%= content %>
        </div>
      <% end %>
    ERB

    def initialize(
      expanded: false,
      expandable: false,
      tabindex: -1,
      level: 1,
      posinset: 1,
      setsize: 1,
      **system_arguments
    )
      @system_arguments = system_arguments

      @system_arguments[:aria] = (@system_arguments[:aria] || {}).deep_merge({
                                                                               level: level,
                                                                               posinset: posinset,
                                                                               setsize: setsize
                                                                             })
      @system_arguments[:aria][:expanded] = expanded if expandable
      @system_arguments[:data] = {} unless @system_arguments.key?(:data)
      @system_arguments[:data]['treegrid-target'] = 'row'
      @system_arguments[:style] = "--treegrid-level: #{level};"
      @system_arguments[:class] = class_names(@system_arguments[:classes], 'treegrid-row')
      @system_arguments.delete(:classes)
      @system_arguments[:role] = 'row'
      @system_arguments[:tabindex] = tabindex
    end
  end
end
