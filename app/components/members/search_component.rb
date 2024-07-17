# frozen_string_literal: true

module Members
  # Component for rendering the search box for a table of members
  class SearchComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(q, tab)
      @q = q
      @tab = tab
    end
    # rubocop:enable Naming/MethodParameterName

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('flex', 'flex-row-reverse')
      }
    end
  end
end
