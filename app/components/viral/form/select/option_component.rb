# frozen_string_literal: true

module Viral
  module Form
    module Select
      # Options for a select component
      class OptionComponent < Viral::Component
        with_collection_parameter :option

        erb_template <<~ERB
          <%= render Viral::BaseComponent.new(**system_arguments) do %>
            <%= @option[:label] %>
          <% end %>
        ERB

        def initialize(option:, selected_value: nil, **args)
          @option = option
          @selected_value = selected_value
          @args = args
        end

        def system_arguments
          @args.tap do |opts|
            opts[:tag] = 'option'
            opts[:value] = @option[:value]
            opts[:selected] = 'selected' if @selected_value == @option[:value]
            opts[:disabled] if @option[:disabled]
          end
        end
      end
    end
  end
end
