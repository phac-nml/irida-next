# frozen_string_literal: true

module Groups
  # Service used to Transfer Groups
  class TransferService < BaseGroupService
    TransferError = Class.new(StandardError)

    def execute(new_namespace)
      validate(new_namespace)

      # Authorize if user can transfer group
      authorize! @group, to: :transfer?

      # Authorize if user can transfer group into namespace
      authorize! new_namespace, to: :transfer_into_namespace?

      @group.update(parent_id: new_namespace.id)

      true
    rescue Groups::TransferService::TransferError => e
      @group.errors.add(:new_namespace, e.message)
      false
    end

    private

    def validate(new_namespace)
      raise TransferError, I18n.t('services.groups.transfer.namespace_empty') if new_namespace.blank?

      if new_namespace.id == @group.id
        raise TransferError,
              I18n.t('services.groups.transfer.same_group_and_namespace')
      end

      if Group.where(parent_id: new_namespace.id).exists?(['path = ? or name = ?', @group.path,
                                                           @group.name])
        raise TransferError, I18n.t('services.groups.transfer.namespace_group_exists')
      end
    end
  end
end
