# frozen_string_literal: true

require 'test_helper'

class GroupLinkMailerTest < ActionMailer::TestCase
  def setup
    @group = groups(:group_five)
    @namespace = groups(:group_one)
  end

  def test_localized_access_granted_user_email
    I18n.available_locales.each do |locale|
      user_emails = Member.user_emails(@group, locale)
      email = GroupLinkMailer.access_granted_user_email(user_emails, @group, @namespace, locale)
      assert_equal user_emails, email.bcc
      assert_equal I18n.t(:'mailers.group_link_mailer.access_granted_user_email.subject',
                          group_name: @group.name,
                          namespace_type: @namespace.type,
                          namespace_name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{I18n.t(:'mailers.group_link_mailer.access_granted_user_email.body_html',
                             group_name: @group.name,
                             namespace_type: @namespace.type,
                             namespace_name: @namespace.name,
                             locale:)}/, email.body.to_s)
    end
  end

  def test_localized_access_revoked_user_email
    I18n.available_locales.each do |locale|
      user_emails = Member.user_emails(@group, locale)
      email = GroupLinkMailer.access_revoked_user_email(user_emails, @group, @namespace, locale)
      assert_equal user_emails, email.bcc
      assert_equal I18n.t(:'mailers.group_link_mailer.access_revoked_user_email.subject',
                          group_name: @group.name,
                          namespace_type: @namespace.type,
                          namespace_name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{I18n.t(:'mailers.group_link_mailer.access_revoked_user_email.body_html',
                             group_name: @group.name,
                             namespace_type: @namespace.type,
                             namespace_name: @namespace.name,
                             locale:)}/, email.body.to_s)
    end
  end

  def test_localized_access_granted_manager_email # rubocop:disable Metrics/AbcSize
    I18n.available_locales.each do |locale|
      manager_emails = Member.manager_emails(@group, locale)
      email = GroupLinkMailer.access_granted_manager_email(manager_emails, @group, @namespace, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.group_link_mailer.access_granted_manager_email.subject',
                          group_name: @group.name,
                          namespace_type: @namespace.type,
                          namespace_name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{Regexp.escape(I18n.t(:'mailers.group_link_mailer.access_granted_manager_email.body_html',
                                           group_name: @group.name,
                                           namespace_type: @namespace.type,
                                           namespace_name: @namespace.name,
                                           locale:))}/, email.body.to_s)
    end
  end

  def test_localized_access_revoked_manager_email # rubocop:disable Metrics/AbcSize
    I18n.available_locales.each do |locale|
      manager_emails = Member.manager_emails(@group, locale)
      email = GroupLinkMailer.access_revoked_manager_email(manager_emails, @group, @namespace, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.group_link_mailer.access_revoked_manager_email.subject',
                          group_name: @group.name,
                          namespace_type: @namespace.type,
                          namespace_name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{Regexp.escape(I18n.t(:'mailers.group_link_mailer.access_revoked_manager_email.body_html',
                                           group_name: @group.name,
                                           namespace_type: @namespace.type,
                                           namespace_name: @namespace.name,
                                           locale:))}/, email.body.to_s)
    end
  end
end
