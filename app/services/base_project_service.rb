# frozen_string_literal: true

# Base root class for service related classes, scoped by project
class BaseProjectService < BaseService
  attr_accessor :project

  def initialize(project, user = nil, params = {})
    super(user, params.except(:project, :project_id))

    @project = project
  end
end
