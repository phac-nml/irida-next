# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Form object for validating automated workflow execution trigger parameters
  class TriggerForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :automated_workflow_execution, :project, :request

    attribute :q
    validate :query_must_be_valid
    validate :query_must_be_present
    validate :query_must_have_results

    def query
      @query ||= Sample::Query.new(
        (q || {}).merge(
          project_ids: [project.id],
          request: request
        )
      )
    end

    def samples
      @samples ||= query.results
    end

    private

    def query_must_be_valid
      errors.add(:q, :invalid) unless query.valid?
    end

    def query_must_be_present
      errors.add(:base, :no_search_params) unless query.advanced_query?
    end

    def query_must_have_results
      return unless query.valid?

      errors.add(:base, :no_samples_found) if samples.blank?
    end
  end
end
