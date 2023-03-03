# frozen_string_literal: true

module Projects
  # Service used to Transfer Projects
  class TransferService < BaseProjectService
    TransferError = Class.new(StandardError)

    def execute(new_namespace) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @new_namespace = new_namespace

      raise TransferError, 'Please select a new namespace for your project.' if @new_namespace.blank?

      raise TransferError, 'Project is already in this namespace.' if @new_namespace.id == project.namespace.parent_id

      unless allowed_to_transfer_project?(current_user, project)
        raise TransferError, "You don't have permission to transfer this project."
      end

      unless allowed_to_transfer_to_namespace?(current_user, @new_namespace)
        raise TransferError, "You don't have permission to transfer projects into that namespace."
      end

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
        raise TransferError, 'Project with same name or path in target namespace already exists'
      end

      project.namespace.update(parent_id: @new_namespace.id)
    end

    def allowed_to_transfer_project?(current_user, project)
      return true if project.creator == current_user
      return true if project.namespace.owner == current_user
      return true if project.namespace.parent.owner == current_user

      false
    end

    def allowed_to_transfer_to_namespace?(current_user, _project)
      return true if @new_namespace.owner == current_user
      return true if @new_namespace.children_allowed?

      false
    end
  end
end
