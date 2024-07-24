# frozen_string_literal: true

module Members
  # Component for rendering the search box for a table of members
  class SearchComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(q, tab, url, search_attribute, placeholder)
      @q = q
      @tab = tab
      @url = url
      @search_attribute = search_attribute
      @placeholder = placeholder
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
