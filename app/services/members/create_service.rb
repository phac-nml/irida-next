# frozen_string_literal: true

module Members
  # Service used to Create Members
  class CreateService < BaseService
    MemberCreateError = Class.new(StandardError)
    attr_accessor :namespace, :member

    def initialize(user = nil, namespace = nil, params = {}, email_notification = false) # rubocop:disable Metrics/ParameterLists, Style/OptionalBooleanParameter
      super(user, params)
      @namespace = namespace
      @email_notification = email_notification
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      authorize! @namespace, to: :create_member? unless namespace.parent.nil? && namespace.owner == current_user

      if member.namespace.owner != current_user &&
         (Member.effective_access_level(namespace, current_user) == Member::AccessLevel::MAINTAINER &&
            (member.access_level > Member::AccessLevel::MAINTAINER))
        raise MemberCreateError, I18n.t('services.members.create.role_not_allowed',
                                        namespace_name: namespace.name,
                                        namespace_type: namespace.class.model_name.human)
      end

      if member.valid?
        has_previous_access = Member.effective_access_level(namespace,
                                                            member.user) > Member::AccessLevel::NO_ACCESS
      end
      if member.save
        send_emails if @email_notification && !has_previous_access
        if @member.user != current_user
          member.create_activity key: 'member.create', owner: current_user, parameters: {
            member_email: @member.user.email
          }
        end
      end

      member
    rescue Members::CreateService::MemberCreateError => e
      member.errors.add(:base, e.message)
      member
    end

    private

    def send_emails
      MemberMailer.access_granted_user_email(member, namespace).deliver_later
    end
  end
end
