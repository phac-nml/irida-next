# frozen_string_literal: true

require 'test_helper'

class MemberMailerTest < ActionMailer::TestCase
  def setup
    @member = members(:group_one_member_john_doe)
    @namespace = @member.namespace
  end

  def test_localized_access_granted_user_email # rubocop:disable Metrics/AbcSize
    I18n.available_locales.each do |locale|
      @member.user.locale = locale
      email = MemberMailer.access_granted_user_email(@member, @namespace)
      assert_equal [@member.user.email], email.to
      assert_equal I18n.t(:'mailers.member_mailer.access_granted_user_email.subject',
                          type: @namespace.type,
                          name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{I18n.t(:'mailers.member_mailer.access_granted_user_email.body_html',
                             type: @namespace.type,
                             name: @namespace.name,
                             locale:)}/, email.body.to_s)
    end
  end

  def test_localized_access_revoked_user_email # rubocop:disable Metrics/AbcSize
    I18n.available_locales.each do |locale|
      @member.user.locale = locale
      email = MemberMailer.access_revoked_user_email(@member, @namespace)
      assert_equal [@member.user.email], email.to
      assert_equal I18n.t(:'mailers.member_mailer.access_revoked_user_email.subject',
                          type: @namespace.type,
                          name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{I18n.t(:'mailers.member_mailer.access_revoked_user_email.body_html',
                             type: @namespace.type,
                             name: @namespace.name,
                             locale:)}/, email.body.to_s)
    end
  end

  def test_localized_access_granted_manager_email # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    I18n.available_locales.each do |locale|
      manager_emails = Member.manager_emails(@namespace, locale, @member)
      email = MemberMailer.access_granted_manager_email(@member, manager_emails, @namespace, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.member_mailer.access_granted_manager_email.subject',
                          first_name: @member.user.first_name.capitalize,
                          last_name: @member.user.last_name.capitalize,
                          email: @member.user.email,
                          type: @namespace.type,
                          name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{Regexp.escape(I18n.t(:'mailers.member_mailer.access_granted_manager_email.body_html',
                                           first_name: @member.user.first_name.capitalize,
                                           last_name: @member.user.last_name.capitalize,
                                           email: @member.user.email,
                                           type: @namespace.type,
                                           name: @namespace.name,
                                           locale:))}/, email.body.to_s)
    end
  end

  def test_access_revoked_manager_email # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    I18n.available_locales.each do |locale|
      manager_emails = Member.manager_emails(@namespace, locale, @member)
      email = MemberMailer.access_revoked_manager_email(@member, manager_emails, @namespace, locale)
      assert_equal manager_emails, email.bcc
      assert_equal I18n.t(:'mailers.member_mailer.access_revoked_manager_email.subject',
                          first_name: @member.user.first_name.capitalize,
                          last_name: @member.user.last_name.capitalize,
                          email: @member.user.email,
                          type: @namespace.type,
                          name: @namespace.name,
                          locale:), email.subject
      assert_match(/#{Regexp.escape(I18n.t(:'mailers.member_mailer.access_revoked_manager_email.body_html',
                                           first_name: @member.user.first_name.capitalize,
                                           last_name: @member.user.last_name.capitalize,
                                           email: @member.user.email,
                                           type: @namespace.type,
                                           name: @namespace.name,
                                           locale:))}/, email.body.to_s)
    end
  end
end
