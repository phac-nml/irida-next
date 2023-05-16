# frozen_string_literal: true

module Projects
  # Service used to Transfer Projects
  class TransferService < BaseProjectService
    TransferError = Class.new(StandardError)

    def execute(new_namespace)
      @new_namespace = new_namespace

      raise TransferError, I18n.t('services.projects.transfer.namespace_empty') if @new_namespace.blank?

      if @new_namespace.id == project.namespace.parent_id
        raise TransferError,
              I18n.t('services.projects.transfer.project_in_namespace')
      end

      # Authorize if user can transfer project
      action_allowed_for_user(project, :transfer?)

      # Authorize if user can transfer project to namespace
      action_allowed_for_user(@new_namespace, :transfer_to_namespace?)

      transfer(project)

      true
    rescue Projects::TransferService::TransferError => e
      project.errors.add(:new_namespace, e.message)
      false
    end

    private

    attr_reader :new_namespace

    def transfer(project)
      if Namespaces::ProjectNamespace.where(parent_id: @new_namespace.id).exists?(['path = ? or name = ?', project.path,
                                                                                   project.name])
        raise TransferError, I18n.t('services.projects.transfer.namespace_project_exists')
      end

      project.namespace.update(parent_id: @new_namespace.id)
    end
  end
end
