# frozen_string_literal: true

module Treegrid
  # Treegrid Row component
  class RowComponent < Component
    erb_template <<-ERB
      <div role="row" <%= @expandable ? 'aria-expanded="#{@expanded}"' : '' %> tabindex="<%= @tabindex %>" data-treegrid-target="row">
        <div role="gridcell" aria-colindex="1">
          <%= content %>
        </div>
      </div>
    ERB

    def initialize(expanded: false, expandable: false, tabindex: '-1')
      @expandable = expandable
      @expanded = expanded
      @tabindex = tabindex
    end
  end
end
