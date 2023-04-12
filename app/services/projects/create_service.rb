# frozen_string_literal: true

module Projects
  # Service used to Create Projects
  class CreateService < BaseService
    ProjectCreateError = Class.new(StandardError)
    attr_accessor :namespace_params, :project, :namespace

    def initialize(user = nil, params = {})
      super(user, params)
      @namespace_params = @params.delete(:namespace_attributes)
      @project = Project.new(params.merge(creator: current_user))
      @namespace = Namespace.find_by(id: namespace_params[:parent_id] || namespace_params[:parent])
    end

    def execute # rubocop:disable Metrics/AbcSize
      raise ProjectCreateError, I18n.t('services.projects.create.namespace_required') if namespace.nil?

      unless allowed_to_modify_projects_in_namespace?(namespace)
        raise ProjectCreateError,
              I18n.t('services.projects.create.no_permission',
                     namespace_type: namespace.class.model_name.human)
      end
      create_associations(project)
      project
    rescue Projects::CreateService::ProjectCreateError => e
      project.errors.add(:base, e.message)
      project
    end

    def create_associations(project)
      project.build_namespace(namespace_params.merge(owner: current_user))
      project.save

      return unless !namespace_owners_include_user?(namespace) && user_has_namespace_maintainer_access?

      Members::CreateService.new(current_user, project.namespace, {
                                   user: current_user,
                                   access_level: Member::AccessLevel::OWNER
                                 }).execute
    end
  end
end
