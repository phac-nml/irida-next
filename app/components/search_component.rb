# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Component for rendering the search box
class SearchComponent < Component
  include Ransack::Helpers::FormHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(query:, url:, search_attribute:, label:, placeholder:, total_count:, value: nil, **kwargs)
    @query = query
    @url = url
    @search_attribute = search_attribute
    @label = label
    @placeholder = placeholder
    @total_count = total_count
    @value = value
    @kwargs = kwargs
  end
  # rubocop:enable Metrics/ParameterLists

  def kwargs
    @kwargs.tap do |args|
      args[:data] ||= {}
      args[:data][:controller] = ['search-field', 'selection', args[:data][:controller]].compact.join(' ')
      args[:data]['turbo-action'] = 'replace'
    end
  end

  def results_message
    if @total_count.zero?
      I18n.t(:'components.search.results_message.zero', search_term: params[:q][@search_attribute])
    elsif @total_count == 1
      I18n.t(:'components.search.results_message.singular', search_term: params[:q][@search_attribute])
    else
      I18n.t(:'components.search.results_message.plural', total_count: @total_count,
                                                          search_term: params[:q][@search_attribute])
    end
  end

  def search_term?
    defined?(params[:q][@search_attribute]) && params[:q][@search_attribute].present?
  end
end
