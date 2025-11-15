# frozen_string_literal: true

module Pathogen
  module Typography
    class List < Component
      # Item slot component for List
      #
      # Simple wrapper that renders list item content
      class Item < ViewComponent::Base
        erb_template <<~ERB
          <%= content %>
        ERB
      end
    end
  end
end
