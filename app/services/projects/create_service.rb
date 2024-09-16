# frozen_string_literal: true

module Projects
  # Service used to Create Projects
  class CreateService < BaseService
    ProjectCreateError = Class.new(StandardError)
    attr_accessor :namespace_params, :project, :namespace

    def initialize(user = nil, params = {})
      super
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

    def create_associations(project) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      project.build_namespace(namespace_params.merge(owner: current_user))
      # We want to authorize that the user can create a project in the parent namespace
      authorize! project.namespace.parent, to: :create?

      project.save

      if project.persisted?
        create_automation_bot
        create_activities
      end

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
      user_params = {
        email: "#{project.namespace.puid}_automation_bot@iridanext.com",
        user_type: User.user_types[:project_automation_bot],
        first_name: project.namespace.puid,
        last_name: 'Automation Bot'
      }

      automation_bot_account = User.new(user_params)
      automation_bot_account.skip_password_validation = true
      automation_bot_account.save

      member_params = {
        user: automation_bot_account,
        namespace: project.namespace,
        access_level: Member::AccessLevel::MAINTAINER
      }

      Members::CreateService.new(current_user, project.namespace, member_params).execute
    end

    private

    def create_activities
      @project.namespace.create_activity key: 'namespaces_project_namespace.create',
                                         owner: current_user

      return unless @project.namespace.parent.group_namespace?

      @project.namespace.parent.create_activity key: 'group.projects.create',
                                                owner: current_user,
                                                parameters: {
                                                  project_id: @project.id,
                                                  project_puid: @project.puid
                                                }
    end
  end
end
