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

    def execute
      raise ProjectCreateError, I18n.t('services.projects.create.namespace_required') if namespace.nil?

      create_associations(project)
      project
    rescue Projects::CreateService::ProjectCreateError => e
      project.errors.add(:base, e.message)
      project
    end

    def create_associations(project) # rubocop:disable Metrics/AbcSize
      project.build_namespace(namespace_params.merge(owner: current_user))
      # We want to authorize that the user can create a project in the parent namespace
      authorize! project.namespace.parent, to: :create?

      project.save

      create_automation_bot if project.persisted?

      return unless !Member.namespace_owners_include_user?(current_user,
                                                           namespace) &&
                    Member.user_has_namespace_maintainer_access?(current_user,
                                                                 namespace)

      Members::CreateService.new(current_user, project.namespace, {
                                   user: current_user,
                                   access_level: Member::AccessLevel::OWNER
                                 }).execute
    end

    def create_automation_bot
      params = {
        token_name: 'automation bot',
        scopes: %w[read_api api],
        access_level: Member::AccessLevel::MAINTAINER,
        is_automation_bot: true
      }

      ::Bots::CreateService.new(current_user, project.namespace, User.user_types[:project_automation_bot],
                                params).execute
    end
  end
end
