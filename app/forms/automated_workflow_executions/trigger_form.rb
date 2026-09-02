# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Form object for validating automated workflow execution trigger parameters
  class TriggerForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :automated_workflow_execution, :project, :request

    attribute :q, :string

    validate :query_must_be_valid
    validate :query_must_be_advanced_query
    validate :samples_must_be_found

    def samples
      @samples ||= query_valid? && query_advanced? ? @query.results : []
    end

    private

    def query
      @query ||= Sample::Query.new(
        q_params.merge(
          project_ids: [project.id],
          request:
        )
      )
    end

    def query_valid?
      @query_valid ||= query.valid?
    end

    def query_advanced?
      @query_advanced ||= query.advanced_query?
    end

    def q_params
      return {} if q.blank?

      JSON.parse(q, symbolize_names: true)
    rescue JSON::ParserError
      {}
    end

    def query_must_be_valid
      return if query_valid?

      # Copy errors from query validation
      query.errors.each do |error|
        errors.add(:q, error.message)
      end
    end

    def query_must_be_advanced_query
      return unless query_valid?

      errors.add(:q, :no_search_params) unless query_advanced?
    end

    def samples_must_be_found
      return unless query_valid? && query_advanced?

      errors.add(:q, :no_samples_found) if samples.blank?
    end
  end
end
