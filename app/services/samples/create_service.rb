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
      unless @project.nil?
        authorize! @project, to: :create_sample?,
                             context: { token: current_user.personal_access_tokens&.active&.write_access&.last }
      end

      sample.save
      sample
    end
  end
end
