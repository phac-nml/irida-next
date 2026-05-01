# frozen_string_literal: true

module Samples
  module V2
    # Encapsulates V2 sample query parsing, persistence, and relation execution.
    class SearchService
      V1_STATE = 1
      V2_STATE = 2

      def initialize(project:, session:, params:, context:)
        @project = project
        @session = session
        @params = params
        @action_name = context.fetch(:action_name)
        @search_params = context.fetch(:search_params) || {}
        @search_state_key = context.fetch(:search_state_key)
      end

      def build_query(raw_json:, sort:)
        tree = AdvancedSearch::V2::Serializer.parse(raw_json)

        Sample::V2::Query.new(
          tree:,
          scope: Sample.where(project_id: project.id),
          sort:,
          page: params[:page],
          limit: params[:limit]
        )
      end

      def store_v2_query(raw_json)
        return if raw_json.blank?

        store(search_state_key, { version: V2_STATE, query_v2: raw_json })
      end

      def persisted_v2_query_for_listing
        return unless v2_query_enabled_for_listing?

        raw_json = current_search_state['query_v2']
        return if raw_json.blank?

        query = build_query(raw_json:, sort: sort_for_listing)
        return query if query.valid?

        clear_persisted_v2_query
        nil
      rescue AdvancedSearch::V2::Serializer::ParseError, ArgumentError
        clear_persisted_v2_query
        nil
      end

      def selection_scope(fallback_scope:)
        if (v2_query = persisted_v2_query_for_listing)
          v2_query.relation
        else
          fallback_scope
        end
      end

      def execute_v2_query(query)
        query.results
      rescue ArgumentError, Pagy::VariableError
        clear_persisted_v2_query
        nil
      end

      def clear_persisted_v2_query
        store(search_state_key, nil)
      end

      def activate_v1_search!
        store(search_state_key, { version: V1_STATE })
      end

      def request_v1_filters_present?
        params[:q].present? && v1_filters_present?(params[:q].to_unsafe_h.with_indifferent_access)
      end

      private

      attr_reader :project, :session, :params, :action_name, :search_params, :search_state_key

      def v2_query_enabled_for_listing?
        action_name.in?(%w[index select]) &&
          Flipper.enabled?(:advanced_search_v2) &&
          current_search_state['version'] == V2_STATE
      end

      def sort_for_listing
        search_params['sort'] || 'updated_at desc'
      end

      def v1_filters_present?(current_search_params)
        current_search_params['name_or_puid_cont'].present? ||
          current_search_params['name_or_puid_in'].present? ||
          current_search_params['groups_attributes'].present?
      end

      def store(session_key, value)
        session[session_key] = value
      end

      def get_store(session_key)
        session[session_key]
      end

      def current_search_state
        state = get_store(search_state_key)
        state.is_a?(Hash) ? state.with_indifferent_access : {}
      end
    end
  end
end
