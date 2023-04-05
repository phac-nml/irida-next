# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseService
    GroupUpdateError = Class.new(StandardError)
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      raise GroupUpdateError, I18n.t('services.groups.update.no_permission') unless allowed_to_modify_group?(group)

      group.update(params)
    rescue Groups::UpdateService::GroupUpdateError => e
      group.errors.add(:base, e.message)
      false
    end
  end
end
