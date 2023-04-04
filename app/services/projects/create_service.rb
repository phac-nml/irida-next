# frozen_string_literal: true

module Projects
  # Service used to Create Projects
  class CreateService < BaseService
    CreateError = Class.new(StandardError)
    attr_accessor :namespace_params

    def initialize(user = nil, params = {})
      super(user, params)
      @namespace_params = @params.delete(:namespace_attributes)
    end

    def execute
      @project = Project.new(params.merge(creator: current_user))
      namespace = Namespace.find_by(id: namespace_params[:parent_id])
      raise CreateError, I18n.t('services.projects.create.namespace_required') if namespace.nil?

      unless Project.allowed_to_create_new_project_in_namespace?(namespace)
        raise CreateError,
              I18n.t('services.projects.create.no_permission',
                     namespace_type: namespace.type.downcase)
      end
      create_associations(@project)
      @project
    rescue Projects::CreateService::CreateError => e
      @project.errors.add(:base, e.message)
      false
    end

    def allowed_to_create_new_project_in_namespace?(namespace)
      if namespace.group_namespace?
        namespace.owners.include?(current_user)
      elsif namespace.user_namespace?
        namespace.owner == current_user
      else
        false
      end
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
