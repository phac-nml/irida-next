# frozen_string_literal: true

module Groups
  # Service used to Update Groups
  class UpdateService < BaseService
    attr_accessor :group

    def initialize(group, user = nil, params = {})
      super(user, params.except(:group, :group_id))
      @group = group
    end

    def execute
      if group.owners.include?(current_user)
        group.update(params)
      else
        group.errors.add(:base, I18n.t('services.groups.update.no_permission'))
      end
    end
  end
end
