# frozen_string_literal: true

module Members
  # Service used to Delete Members
  class DestroyService < BaseService
    MemberDestroyError = Class.new(StandardError)
    attr_accessor :member, :namespace

    def initialize(member, namespace, user = nil, params = {})
      super(user, params)
      @member = member
      @namespace = namespace
    end

    def execute # rubocop:disable Metrics/AbcSize
      unless current_user != member.user
        raise MemberDestroyError, I18n.t('services.members.destroy.cannot_remove_self',
                                         namespace_type: namespace.type.downcase)
      end

      unless allowed_to_modify_members_in_namespace?(namespace)
        raise MemberDestroyError, I18n.t('services.members.destroy.no_permission',
                                         namespace_type: namespace.type.downcase)
      end

      member.destroy
    rescue Members::DestroyService::MemberDestroyError => e
      member.errors.add(:base, e.message)
      false
    end
  end
end
