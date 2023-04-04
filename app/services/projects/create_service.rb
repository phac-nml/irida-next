# frozen_string_literal: true

module Projects
  # Service used to Create Projects
  class CreateService < BaseService
    ProjectCreateError = Class.new(StandardError)
    attr_accessor :namespace_params

    def initialize(user = nil, params = {})
      super(user, params)
      @namespace_params = @params.delete(:namespace_attributes)
    end

    def execute
      @project = Project.new(params.merge(creator: current_user))
      namespace = Namespace.find_by(id: namespace_params[:parent_id])
      raise ProjectCreateError, I18n.t('services.projects.create.namespace_required') if namespace.nil?

      unless allowed_to_modify_projects_in_namespace?(namespace)
        raise ProjectCreateError,
              I18n.t('services.projects.create.no_permission',
                     namespace_type: namespace.type.downcase)
      end
      create_associations(@project)
      @project
    rescue Projects::CreateService::ProjectCreateError => e
      @project.errors.add(:base, e.message)
      false
    end

    def create_associations(project)
      project.build_namespace(namespace_params.merge(owner: current_user))
      project.save
      Members::CreateService.new(current_user, @project.namespace, {
                                   user: current_user,
                                   access_level: Member::AccessLevel::OWNER
                                 }).execute
    end
  end
end
