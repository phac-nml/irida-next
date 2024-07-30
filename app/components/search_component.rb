# frozen_string_literal: true

# Component for rendering the search box
class SearchComponent < Component
  include Ransack::Helpers::FormHelper

  # rubocop:disable Naming/MethodParameterName
  def initialize(q:, url:, search_attribute:, placeholder:, tab: '')
    @q = q
    @url = url
    @search_attribute = search_attribute
    @placeholder = placeholder
    @tab = tab
  end
  # rubocop:enable Naming/MethodParameterName
end
