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

      group.update(parent_id: new_namespace.id)

      true
    rescue Groups::TransferService::TransferError => e
      group.errors.add(:new_namespace, e.message)
      false
    end

    private

    def validate(new_namespace)
      raise TransferError, I18n.t('services.groups.transfer.namespace_empty') if new_namespace.blank?

      if new_namespace.id == @group.id
        raise TransferError,
              I18n.t('services.groups.transfer.same_group_and_namespace')
      end

      return unless new_namespace.id == @group.parent_id

      raise TransferError,
            I18n.t('services.groups.transfer.group_in_namespace')
    end
  end
end
