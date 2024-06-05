# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    attr_accessor :project, :sample

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
      @sample = Sample.new(params.merge(project_id: project&.id))
    end

    def execute
      authorize! @project, to: :create_sample? unless @project.nil?

      sample.save
      sample
    end
  end
end
