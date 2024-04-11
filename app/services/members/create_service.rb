# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      authorize! @namespace, to: :create_member? unless namespace.parent.nil? && namespace.owner == current_user

      if member.namespace.owner != current_user &&
         (Member.user_has_namespace_maintainer_access?(current_user,
                                                       namespace) &&
            (member.access_level > Member::AccessLevel::MAINTAINER))
        raise MemberCreateError, I18n.t('services.members.create.role_not_allowed',
                                        namespace_name: namespace.name,
                                        namespace_type: namespace.class.model_name.human)
      end

      had_access = Member.can_view?(member.user, member.namespace, false) # TODO: change to true
      send_emails(had_access) if member.save

      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end

    private

    def send_emails(had_access) # rubocop:disable Metrics/AbcSize
      return unless member.previously_new_record?

      access = if had_access
                 'changed'
               else
                 'granted'
               end

      MemberMailer.access_inform_user_email(member, access).deliver_later
      manager_memberships = Member.for_namespace_and_ancestors(member.namespace).not_expired
                                  .where(access_level: Member::AccessLevel.manageable)
      managers = User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: member.user.id))
                     .distinct
      managers.each do |manager|
        MemberMailer.access_inform_manager_email(member, manager, access).deliver_later
      end
    end
  end
end
