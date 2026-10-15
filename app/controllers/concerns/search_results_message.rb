# frozen_string_literal: true

# Shared pagy-based results-message helpers for advanced/quick search UIs.
module SearchResultsMessage
  extend ActiveSupport::Concern

  private

  def advanced_search_results_message
    if @pagy&.count&.zero?
      I18n.t(:'components.search.advanced.results_message.zero')
    elsif @pagy&.count == 1 # rubocop:disable Style/CollectionQuerying
      I18n.t(:'components.search.advanced.results_message.singular')
    else
      I18n.t(:'components.search.advanced.results_message.plural', total_count: @pagy&.count)
    end
  end

  def quick_search_results_message(search_term)
    if @pagy&.count&.zero?
      I18n.t(:'components.search.results_message.zero', search_term: search_term)
    elsif @pagy&.count == 1 # rubocop:disable Style/CollectionQuerying
      I18n.t(:'components.search.results_message.singular', search_term: search_term)
    else
      I18n.t(:'components.search.results_message.plural', total_count: @pagy&.count,
                                                          search_term: search_term)
    end
  end
end
