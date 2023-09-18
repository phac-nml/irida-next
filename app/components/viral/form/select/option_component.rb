# frozen_string_literal: true

module Viral
  module Form
    module Select
      class OptionComponent < ViewComponent::Base
        with_collection_parameter :option

        erb_template <<~ERB
          <option value="<%= @option[:value] %>"><%= @option[:label] %></option>
        ERB

        def initialize(option:)
          @option = option
        end
      end
    end
  end
end
