# frozen_string_literal: true

module GlobalSearch
  module Providers
    # Search provider for workflow executions.
    class WorkflowExecutions < Base
      TYPE = 'workflow_executions'

      def search(query:, match_sources:, filters:, limit:)
        return [] if query.blank?

        include_identifier = match_sources.include?('identifier')
        include_name = match_sources.include?('name')
        return [] unless include_identifier || include_name

        workflow_execution_scope(query:, include_identifier:, include_name:, filters:, limit:)
          .filter_map { |workflow_execution| build_workflow_execution_result(workflow_execution, query) }
          .first(limit)
      end

      private

      def workflow_execution_scope(query:, include_identifier:, include_name:, filters:, limit:)
        scope = candidate_scope
        scope = apply_created_filters(scope, created_from: filters[:created_from], created_to: filters[:created_to])
        scope = scope.where(state: filters[:workflow_state]) if filters[:workflow_state].present?
        scope = scope.where(search_clause(include_identifier:, include_name:), search_binds(query:))
        scope.includes(:namespace, :submitter).order(updated_at: :desc).limit(limit * 6)
      end

      def build_workflow_execution_result(workflow_execution, query)
        return unless allowed_to?(:read?, workflow_execution)

        match = match_details(workflow_execution, query)

        build_result(
          type: TYPE,
          record_id: workflow_execution.id,
          title: workflow_execution.name.presence || workflow_execution.id,
          subtitle: workflow_execution_subtitle(workflow_execution),
          url: workflow_execution_path_for(workflow_execution),
          match_tags: match[:tags],
          score_bucket: match[:bucket],
          updated_at: workflow_execution.updated_at
        )
      end

      def candidate_scope
        namespace_ids = accessible_namespace_ids

        scope = WorkflowExecution.where(submitter_id: current_user.id)
        return scope if namespace_ids.empty?

        scope.or(WorkflowExecution.where(namespace_id: namespace_ids))
      end

      def accessible_namespace_ids
        @accessible_namespace_ids ||= (accessible_project_namespace_ids + accessible_group_ids).uniq
      end

      def accessible_project_namespace_ids
        authorized_scope(Project, type: :relation).pluck(:namespace_id)
      end

      def accessible_group_ids
        authorized_scope(Group, type: :relation).pluck(:id)
      end

      def search_clause(include_identifier:, include_name:)
        clauses = []
        if include_identifier
          clauses << '(workflow_executions.id::text = :exact OR workflow_executions.run_id ILIKE :pattern)'
        end
        clauses << '(workflow_executions.name ILIKE :pattern)' if include_name
        clauses.join(' OR ')
      end

      def workflow_execution_path_for(workflow_execution)
        namespace = workflow_execution.namespace

        return workflow_execution_path(workflow_execution) if workflow_execution.submitter_id == current_user.id
        return workflow_execution_path(workflow_execution) if namespace.blank?

        if namespace.type == Group.sti_name
          group_workflow_execution_path(namespace, workflow_execution)
        else
          namespace_project_workflow_execution_path(namespace.parent, namespace.project, workflow_execution)
        end
      end

      def workflow_execution_subtitle(workflow_execution)
        namespace_name = workflow_execution.namespace&.name || 'Personal'
        "#{namespace_name} · #{workflow_execution.state}"
      end

      def match_details(workflow_execution, query)
        identifier_values = [workflow_execution.id, workflow_execution.run_id]
        name_values = [workflow_execution.name]

        return { tags: ['Exact ID'], bucket: SCORE_BUCKET_EXACT_IDENTIFIER } if exact_on_any?(identifier_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_EXACT_NAME } if exact_on_any?(name_values, query)
        return { tags: ['Name'], bucket: SCORE_BUCKET_PREFIX } if prefix_on_any?(identifier_values + name_values, query)

        { tags: ['Name'], bucket: SCORE_BUCKET_FUZZY }
      end
    end
  end
end
