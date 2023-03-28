# frozen_string_literal: true

module Projects
  # Service used to Create Projects
  class CreateService < BaseService
    attr_accessor :namespace_params

    def initialize(user = nil, params = {})
      super(user, params)
      @namespace_params = @params.delete(:namespace_attributes)
    end

    def execute
      @project = Project.new(params.merge(creator: current_user))

      @project.build_namespace(namespace_params.merge(owner: current_user))

      @project.save

      Members::CreateService.new(current_user, {
                                   user: current_user, namespace: @project.namespace,
                                   access_level: Member::AccessLevel::OWNER,
                                   type: 'ProjectMember'
                                 }).execute

      @project
    end
  end
end
