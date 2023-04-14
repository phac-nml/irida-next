# frozen_string_literal: true

module Groups
  # Service used to Create Groups
  class CreateService < BaseService
    GroupCreateError = Class.new(StandardError)
    attr_accessor :group

    def initialize(user = nil, params = {})
      super(user, params)
      @group = Group.new(params.merge(owner: current_user))
    end

    def execute # rubocop:disable Metrics/AbcSize
      unless group.parent.nil? || allowed_to_modify_group?(group.parent)
        raise GroupCreateError, I18n.t('services.groups.create.no_permission',
                                       namespace_type: group.class.model_name.human)
      end

      group.save

      if group.parent.nil?
        Members::CreateService.new(current_user, group, {
                                     user: current_user,
                                     access_level: Member::AccessLevel::OWNER
                                   }).execute
      end

      group
    rescue Groups::CreateService::GroupCreateError => e
      group.errors.add(:base, e.message)
      group
    end
  end
end
