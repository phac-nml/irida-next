# frozen_string_literal: true

# Global search endpoints for mixed cross-resource search.
class GlobalSearchController < ApplicationController
  before_action :ensure_enabled

  def index
    @search = GlobalSearch::Query.new(current_user, query_params).execute
    @workflow_states = WorkflowExecution.states.keys

    respond_to do |format|
      format.html
      format.json { render json: payload(@search) }
    end
  end

  private

  def ensure_enabled
    not_found unless Flipper.enabled?(:global_search)
  end

  def payload(search)
    {
      query: search.query,
      meta: search.meta,
      results: search.results.map(&:to_h)
    }
  end

  def query_params
    params.permit(
      :q,
      :sort,
      :workflow_state,
      :created_from,
      :created_to,
      :limit,
      :per_type_limit,
      types: [],
      match_sources: []
    ).to_h.symbolize_keys
  end
end
