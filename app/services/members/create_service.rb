# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    include MailerHelper
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {}, email_notification = false) # rubocop:disable Metrics/ParameterLists, Style/OptionalBooleanParameter
      super(user, params)
      @namespace = namespace
      @email_notification = email_notification
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      authorize! @namespace, to: :create_member? unless namespace.parent.nil? && namespace.owner == current_user

      if member.namespace.owner != current_user &&
         (Member.user_has_namespace_maintainer_access?(current_user,
                                                       namespace) &&
            (member.access_level > Member::AccessLevel::MAINTAINER))
        raise MemberCreateError, I18n.t('services.members.create.role_not_allowed',
                                        namespace_name: namespace.name,
                                        namespace_type: namespace.class.model_name.human)
      end

      has_previous_access = Member.can_view?(member.user, namespace, true) if member.valid?
      send_emails if member.save && @email_notification && !has_previous_access
      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end

    private

    def send_emails
      MemberMailer.access_granted_user_email(member, namespace).deliver_later
      manager_emails = manager_emails(member, namespace)
      return if manager_emails.empty?

      MemberMailer.access_granted_manager_email(member, manager_emails, namespace).deliver_later
    end
  end
end
