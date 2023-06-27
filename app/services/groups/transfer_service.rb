# frozen_string_literal: true

module Groups
  # Service used to Transfer Groups
  class TransferService < BaseGroupService
    TransferError = Class.new(StandardError)

    def execute(new_namespace)
      @new_namespace = new_namespace
      raise TransferError, I18n.t('services.groups.transfer.namespace_empty') if @new_namespace.blank?

      if @new_namespace.id == group.id
        raise TransferError,
              I18n.t('services.groups.transfer.group_in_namespace')
      end

      true
    rescue Groups::TransferService::TransferError => e
      group.errors.add(:new_namespace, e.message)
      false
    end
  end
end
