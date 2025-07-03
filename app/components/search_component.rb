# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Component for rendering the search box
class SearchComponent < Component
  include Ransack::Helpers::FormHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(query:, url:, search_attribute:, placeholder:, total_count:, value: nil, **kwargs)
    @query = query
    @url = url
    @search_attribute = search_attribute
    @placeholder = placeholder
    @total_count = total_count
    @value = value
    @kwargs = kwargs
  end
  # rubocop:enable Metrics/ParameterLists

  def results_message
    if @total_count.zero?
      "No results found for '#{params[:q][@search_attribute]}'"
    elsif @total_count == 1
      "1 result found for '#{params[:q][@search_attribute]}'"
    else
      "#{@total_count} results found for '#{params[:q][@search_attribute]}'"
    end
  end
end
