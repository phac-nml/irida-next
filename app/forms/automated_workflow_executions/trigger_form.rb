# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Form object for validating automated workflow execution trigger parameters
  class TriggerForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :automated_workflow_execution, :project, :request

    attribute :q

    validate :query_must_be_advanced_query
    validate :samples_must_be_found

    def samples
      @samples ||= query.results
    end

    def search_group_class
      Sample::SearchGroup
    end

    def query_object
      query
    end

    private

    def query
      @query ||= Sample::Query.new(
        (q || {}).merge(
          project_ids: [project.id],
          request:
        )
      )
    end

    def query_must_be_advanced_query
      errors.add(:q, :no_search_params) unless query.advanced_query?
    end

    def samples_must_be_found
      errors.add(:q, :no_samples_found) if samples.blank?
    end
  end
end
