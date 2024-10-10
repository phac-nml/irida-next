# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Component for rendering the search box
class SearchComponent < Component
  include Ransack::Helpers::FormHelper

  def initialize(query:, url:, search_attribute:, placeholder:, **kwargs)
    @query = query
    @url = url
    @search_attribute = search_attribute
    @placeholder = placeholder
    @kwargs = kwargs
  end
end
