# frozen_string_literal: true

module Groups
  # Service used to Delete Groups
  class DestroyService < BaseService
    GroupDestroyError = Class.new(StandardError)
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      raise GroupDestroyError, I18n.t('services.groups.destroy.no_permission') unless allowed_to_destroy_group?(group)

      group.destroy
    rescue Groups::DestroyService::GroupDestroyError => e
      group.errors.add(:base, e.message)
      false
    end
  end
end
