# frozen_string_literal: true

module Projects
  # Service used to Transfer Projects
  class TransferService < BaseProjectService
    TransferError = Class.new(StandardError)
    attr_reader :new_namespace, :old_namespace

    def execute(new_namespace) # rubocop:disable Metrics/AbcSize
      @new_namespace = new_namespace
      @old_namespace = @project.parent

      raise TransferError, I18n.t('services.projects.transfer.namespace_empty') if @new_namespace.blank?

      if @new_namespace.id == project.namespace.parent_id
        raise TransferError,
              I18n.t('services.projects.transfer.project_in_namespace')
      end

      # Authorize if user can transfer project
      authorize! @project, to: :transfer?

      # Authorize if user can transfer project to namespace
      authorize! @new_namespace, to: :transfer_into_namespace?

      transfer(project)

      @new_namespace.update_metadata_summary_by_namespace_transfer(@project.namespace, @old_namespace)

      true
    rescue Projects::TransferService::TransferError => e
      project.errors.add(:new_namespace, e.message)
      false
    end

    private

    def transfer(project) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if Namespaces::ProjectNamespace.where(parent_id: new_namespace.id).exists?(['path = ? or name = ?',
                                                                                  project.path, project.name])
        raise TransferError, I18n.t('services.projects.transfer.namespace_project_exists')
      end

      project_ancestor_member_user_ids = Member.for_namespace_and_ancestors(project.namespace).select(:user_id)
      new_namespace_member_ids = Member.for_namespace_and_ancestors(new_namespace)
                                       .where(user_id: project_ancestor_member_user_ids).select(&:id)

      Namespaces::ProjectNamespace.public_activity_off

      project.namespace.update(parent_id: new_namespace.id)

      Namespaces::ProjectNamespace.public_activity_on

      project.namespace.create_activity action: :transfer, owner: current_user,
                                        parameters:
      {
        project_name: project.name,
        old_namespace: @old_namespace.name,
        new_namespace: @new_namespace.name
      }

      UpdateMembershipsJob.perform_later(new_namespace_member_ids)
    end
  end
end
