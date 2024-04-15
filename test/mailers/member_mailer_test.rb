# frozen_string_literal: true

require 'test_helper'

class MemberMailerTest < ActionMailer::TestCase
  def setup
    @member = members(:group_one_member_john_doe)
    @namespace = @member.namespace
    manager_memberships = Member.for_namespace_and_ancestors(@namespace).not_expired
                                .where(access_level: Member::AccessLevel.manageable)
    managers = User.where(id: manager_memberships.select(:user_id)).and(User.where.not(id: @member.user.id)).distinct
    @manager_emails = managers.pluck(:email)
  end

  def test_granted_access_email # rubocop:disable Metrics/AbcSize
    email = MemberMailer.access_email(@member, @manager_emails, 'granted', @namespace)
    assert email.to
    assert_equal [@member.user.email], email.to
    assert_equal @manager_emails, email.bcc
    assert_equal I18n.t(:'member_mailer.access_email.access_granted_subject',
                        first_name: @member.user.first_name.capitalize,
                        last_name: @member.user.last_name.capitalize,
                        type: @namespace.type,
                        id: @namespace.id), email.subject
    assert_match(/access_email/, email.body.to_s)
  end

  def test_revoked_access_email # rubocop:disable Metrics/AbcSize
    email = MemberMailer.access_email(@member, @manager_emails, 'revoked', @namespace)
    assert email.to
    assert_equal [@member.user.email], email.to
    assert_equal @manager_emails, email.bcc
    assert_equal I18n.t(:'member_mailer.access_email.access_revoked_subject',
                        first_name: @member.user.first_name.capitalize,
                        last_name: @member.user.last_name.capitalize,
                        type: @namespace.type,
                        id: @namespace.id), email.subject
    assert_match(/access_email/, email.body.to_s)
  end
end
