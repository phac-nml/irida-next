# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    attr_accessor :project, :sample, :token

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
      @token = params.delete(:token)
      @sample = Sample.new(params.merge(project_id: project&.id))
    end

    def execute
      unless @project.nil?
        authorize! @project, to: :create_sample?,
                             context: { token: }
      end

      sample.save
      sample
    end
  end
end
