# frozen_string_literal: true

# Component for rendering the search box
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
