# frozen_string_literal: true

# Treegrid component
class TreegridComponent < Component
  erb_template <<-ERB
    <%= tag.div(**@system_arguments) do %>
      <% rows.each do |row| %>
        <%= row %>
      <% end %>
    <% end %>
  ERB

  renders_many :rows, Treegrid::RowComponent

  def initialize(**system_arguments)
    @system_arguments = system_arguments

    @system_arguments[:class] = class_names(@system_arguments[:classes], 'treegrid-container')
    @system_arguments.delete(:classes)
    @system_arguments[:role] = 'treegrid'
    @system_arguments[:aria] ||= {}
    @system_arguments[:aria][:readonly] = 'true'
    @system_arguments[:data] ||= {}
    @system_arguments[:data][:controller] = 'treegrid'
    @system_arguments[:data]['treegrid-expand-text-value'] = I18n.t(:'components.treegrid.row.expand')
    @system_arguments[:data]['treegrid-collapse-text-value'] = I18n.t(:'components.treegrid.row.collapse')
  end
end
