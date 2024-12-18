# frozen_string_literal: true

# Queries for samples table
module SamplesQuery
  extend ActiveSupport::Concern

  # Determines which pagy method to use when loading the samples table based on @query
  def pagy_for_samples_query
    limit = params[:limit] || 20
    if @query.advanced_query
      pagy_searchkick(@query.results(:searchkick_pagy), limit:)
    else
      pagy(@query.results(:ransack), limit:)
    end
  end

  def select_query
    @query.results(@query.advanced_query ? :searchkick : :ransack)
          .where(updated_at: ..params[:timestamp].to_datetime).select(:id).pluck(:id)
  end
end
