# frozen_string_literal: true

# Determines which pagy method to use when loading samples table
module SamplesQuery
  extend ActiveSupport::Concern

  def pagy_for_samples_query
    limit = params[:limit] || 20
    if @query.advanced_query
      pagy_searchkick(@query.results(:searchkick_pagy), limit:)
    else
      pagy(@query.results(:ransack), limit:)
    end
  end
end
