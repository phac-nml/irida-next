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
    group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.namespace_group_link.attributes.group_id.taken')
    )
  end

  test '#validates access level out of range' do
    group_group_link = NamespaceGroupLink.new(group_id: @group_to_share.id, namespace_id: @group.id,
                                              group_access_level: Member::AccessLevel::ANALYST + 100_000)

    assert_not group_group_link.save
    group_group_link.errors.full_messages.include?(
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
    shared_with_group_links = []

    group_and_ancestors.each do |group|
      shared_with_group_links << group.shared_with_group_links
    end

    shared_with_group_links = shared_with_group_links.flatten

    assert shared_with_group_links.count == namespace_group_links.count
    assert_same_unique_elements(namespace_group_links, shared_with_group_links)
  end
end
