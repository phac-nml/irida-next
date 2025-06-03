# frozen_string_literal: true

module Treegrid
  # Treegrid Row component
  class RowComponent < Component
    erb_template <<-ERB
      <%= tag.div(class: "treegrid-row", role: "row", aria: @aria, data: @data, style: @style, tabindex: @tabindex) do %>
        <div role="gridcell" aria-colindex="1">
          <%= content %>
        </div>
      <% end %>
    ERB

    def initialize(expanded: false, expandable: false, tabindex: '-1', level: '1', posinset: '1', setsize: '1') # rubocop:disable Metrics/ParameterLists
      @tabindex = tabindex
      @level = level

      @aria = {
        level: level,
        posinset: posinset,
        setsize: setsize
      }
      @aria[:expanded] = expanded if expandable
      @data = { 'treegrid-target': 'row' }
      @style = "--treegrid-level: #{level};"
    end
  end
end
