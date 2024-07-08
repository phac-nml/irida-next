# frozen_string_literal: true

require 'test_helper'

class NamespaceGroupLinkTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group = groups(:group_one)
    @group_to_share = groups(:david_doe_group_four)
  end

  test 'group to group link is valid' do
    group_group_link = namespace_group_links(:namespace_group_link5)

    assert group_group_link.valid?
  end

  test 'cannot create multiple group to group links with the same groups' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: @group.id,
                                              group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save

    assert group_group_link.errors.full_messages_for(:group_id).first.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.group_id.taken')
    )
  end

  test 'cannot create self to self group links' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: @group_to_share.id,
                                              group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    assert group_group_link.errors.full_messages_for(:group_id).include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.group_id.comparison',
             group_id: @group_to_share.id)
    )
  end

  test '#validates access level out of range' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: @group.id,
                                              group_access_level: Member::AccessLevel::ANALYST + 100_000)

    assert_not group_group_link.save

    assert group_group_link.errors.full_messages_for(:group_access_level).first.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.group_access_level.inclusion')
    )
  end

  test '#validates invalid group to share' do
    group_group_link = NamespaceGroupLink.new(group_id: nil, namespace_id: @group.id,
                                              group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    assert group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.group_id.blank')
    )
  end

  test '#validates invalid group to share with' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: nil,
                                              group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    assert group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.namespace_id.blank')
    )
  end

  test '#validates the namespace type is either Group or Project' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: @user.id,
                                              group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save

    assert group_group_link.errors.messages.values.flatten.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.namespace_type.inclusion')
    )
  end

  test '#scope for_namespace_and_ancestors returns the correct collection' do
    group_group_link = namespace_group_links(:namespace_group_link2)

    namespace = group_group_link.namespace

    namespace_group_links = NamespaceGroupLink.for_namespace_and_ancestors(namespace)

    group_and_ancestors = namespace.self_and_ancestors
    shared_with_group_links = group_and_ancestors.map(&:shared_with_group_links)

    shared_with_group_links = shared_with_group_links.flatten

    assert shared_with_group_links.count == namespace_group_links.count
    assert_same_unique_elements(namespace_group_links, shared_with_group_links)
  end

  test 'set_namespace_type' do
    namespace_group_link = NamespaceGroupLink.new
    namespace = namespaces_project_namespaces(:project20_namespace)

    assert_nil namespace_group_link.namespace
    assert_nil namespace_group_link.namespace_type

    namespace_group_link.save
    assert_nil namespace_group_link.namespace_type

    namespace_group_link.namespace = namespace
    namespace_group_link.save

    assert_equal namespace.type, namespace_group_link.namespace_type
  end

  test 'send_access_revoked_emails' do
    group_group_link = namespace_group_links(:namespace_group_link5)

    assert_enqueued_emails 3 do
      group_group_link.send_access_revoked_emails

      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group_group_link.group, locale)
        manager_emails = Member.manager_emails(group_group_link.namespace, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_revoked_user_email,
                                     args: [user_emails, group_group_link.group,
                                            group_group_link.namespace, locale]
        end
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_revoked_manager_email,
                                   args: [manager_emails, group_group_link.group,
                                          group_group_link.namespace, locale]
      end
    end
  end

  test 'send_access_granted_emails' do
    group_group_link = namespace_group_links(:namespace_group_link5)

    assert_enqueued_emails 3 do
      group_group_link.send_access_granted_emails

      I18n.available_locales.each do |locale|
        user_emails = Member.user_emails(group_group_link.group, locale)
        manager_emails = Member.manager_emails(group_group_link.namespace, locale)
        unless user_emails.empty?
          assert_enqueued_email_with GroupLinkMailer, :access_granted_user_email,
                                     args: [user_emails, group_group_link.group,
                                            group_group_link.namespace, locale]
        end
        next if manager_emails.empty?

        assert_enqueued_email_with GroupLinkMailer, :access_granted_manager_email,
                                   args: [manager_emails, group_group_link.group,
                                          group_group_link.namespace, locale]
      end
    end
  end
end
