# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Component for rendering the search box
class SearchComponent < Component
  include Ransack::Helpers::FormHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(query:, url:, search_attribute:, placeholder:, value: '', **kwargs)
    @query = query
    @url = url
    @value = value
    @search_attribute = search_attribute
    @placeholder = placeholder
    @kwargs = kwargs
  end
  # rubocop:enable Metrics/ParameterLists
end
