# frozen_string_literal: true

module GroupLinks
  # Service used to Create NamespaceGroupLinks
  class GroupLinkService < BaseService
    NamespaceGroupLinkError = Class.new(StandardError)
    attr_accessor :group_id, :namespace, :namespace_group_link

    def initialize(user, namespace, params)
      super(user, params)
      @group_id = params[:group_id]
      @namespace = namespace
      @namespace_group_link = NamespaceGroupLink.new(params.merge(namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      unless [Group.sti_name, Namespaces::ProjectNamespace.sti_name].include?(namespace.type)
        raise NamespaceGroupLinkError, I18n.t('services.groups.share.invalid_namespace_type')
      end

      authorize! namespace, to: :link_namespace_with_group?

      group = Group.find_by(id: group_id)

      raise NamespaceGroupLinkError, I18n.t('services.groups.share.group_not_found', group_id:) if group.nil?

      # TODO: move to callback
      manager_memberships = Member.where(namespace_id: group_id).not_expired
                                  .where(access_level: Member::AccessLevel.manageable)
      managers = User.where(id: manager_memberships.select(:user_id)).distinct
      manager_emails = managers.pluck(:email)
      memberships = Member.where(namespace_id: group_id).not_expired

      memberships.each do |member|
        next if Member.can_view?(member.user, namespace, false) # TODO: change to true

        MemberMailer.access_email(member, manager_emails, 'granted', namespace).deliver_later
      end

      namespace_group_link.save

      namespace_group_link
    rescue GroupLinks::GroupLinkService::NamespaceGroupLinkError => e
      @namespace.errors.add(:base, e.message)
      false
    end
  end
end
