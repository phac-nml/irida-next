# frozen_string_literal: true

module Projects
  # Service used to Transfer Projects
  class TransferService < BaseProjectService
    def initialize(project, user = nil, transfer_form = nil)
      super(project, user)
      @transfer_form = transfer_form
    end

    def execute # rubocop:disable Naming/PredicateMethod
      return false unless @transfer_form.valid?

      @new_namespace = @transfer_form.new_namespace
      @old_namespace = @project.parent

      # Authorize if user can transfer project
      authorize! @project, to: :transfer?

      # Authorize if user can transfer project to namespace
      authorize! @new_namespace, to: :transfer_into_namespace?

      transfer(project)

      @new_namespace.update_metadata_summary_by_namespace_transfer(@project.namespace, @old_namespace)

      update_samples_count

      true
    end

    private

    def transfer(project)
      project_ancestor_member_user_ids = Member.for_namespace_and_ancestors(project.namespace).select(:user_id)
      new_namespace_member_ids = Member.for_namespace_and_ancestors(@new_namespace)
                                       .where(user_id: project_ancestor_member_user_ids).select(&:id)

      parameters = update_params(project)

      project.namespace.update(parameters)

      create_activities(project)

      UpdateMembershipsJob.perform_later(new_namespace_member_ids)
    end

    def create_activities(project) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      project.namespace.create_activity action: :transfer,
                                        owner: current_user,
                                        parameters:
                                        {
                                          project_id: project.id,
                                          project_puid: project.namespace.puid,
                                          old_namespace: @old_namespace.puid,
                                          new_namespace: @new_namespace.puid,
                                          action: 'project_namespace_transfer'
                                        }

      @old_namespace.create_activity key: 'group.projects.transfer_out',
                                     owner: current_user,
                                     parameters:
                                     {
                                       project_id: project.id,
                                       project_puid: project.namespace.puid,
                                       old_namespace: @old_namespace.puid,
                                       new_namespace: @new_namespace.puid,
                                       action: 'project_namespace_transfer'
                                     }

      return unless @new_namespace.group_namespace?

      @new_namespace.create_activity key: 'group.projects.transfer_in',
                                     owner: current_user,
                                     parameters:
                                     {
                                       project_id: project.id,
                                       project_puid: project.namespace.puid,
                                       old_namespace: @old_namespace.puid,
                                       new_namespace: @new_namespace.puid,
                                       action: 'project_namespace_transfer'
                                     }
    end

    def update_params(project)
      params = { parent_id: @new_namespace.id }

      if @new_namespace.group_namespace? && @new_namespace.public? && !project.namespace.public?
        params[:public] = true
      elsif @new_namespace.group_namespace? && !@new_namespace.public? && project.namespace.public?
        params[:public] = false
      end

      params
    end

    def update_samples_count
      transferred_samples_count = @project.samples.size
      if @old_namespace.type == 'Group'
        @old_namespace.update_samples_count_by_transfer_service(@new_namespace, transferred_samples_count,
                                                                @new_namespace.type)
      elsif @new_namespace.type == 'Group'
        @new_namespace.update_samples_count_by_addition_services(transferred_samples_count)
      end
    end
  end
end
