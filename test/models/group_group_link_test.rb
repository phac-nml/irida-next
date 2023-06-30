# frozen_string_literal: true

require 'test_helper'

class GroupGroupLinkTest < ActiveSupport::TestCase
  def setup
    @group = groups(:group_one)
    @group_to_share = groups(:david_doe_group_four)
  end

  test 'group to group link is valid' do
    group_group_link = GroupGroupLink.new(shared_group_id: @group_to_share.id, shared_with_group_id: @group.id,
                                          group_access_level: Member::AccessLevel::ANALYST)

    assert group_group_link.save
  end

  test 'cannot create multiple group to group links with the same groups' do
    group_group_link = GroupGroupLink.new(shared_group_id: @group_to_share.id, shared_with_group_id: @group.id,
                                          group_access_level: Member::AccessLevel::ANALYST)

    assert group_group_link.save

    group_group_link = GroupGroupLink.new(shared_group_id: @group_to_share.id, shared_with_group_id: @group.id,
                                          group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.group_group_link.attributes.shared_group_id.taken')
    )
  end

  test '#validates access level out of range' do
    group_group_link = GroupGroupLink.new(shared_group_id: @group_to_share.id, shared_with_group_id: @group.id,
                                          group_access_level: Member::AccessLevel::ANALYST + 100_000)

    assert_not group_group_link.save
    group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.group_group_link.attributes.group_access_level.inclusion')
    )
  end

  test '#validates invalid group to share' do
    group_group_link = GroupGroupLink.new(shared_group_id: nil, shared_with_group_id: @group.id,
                                          group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    assert group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.group_group_link.attributes.shared_group_id.blank')
    )
  end

  test '#validates invalid group to share with' do
    group_group_link = GroupGroupLink.new(shared_group_id: @group_to_share.id, shared_with_group_id: nil,
                                          group_access_level: Member::AccessLevel::ANALYST)

    assert_not group_group_link.save
    assert group_group_link.errors.full_messages.include?(
      I18n.t('activerecord.errors.models.group_group_link.attributes.shared_with_group_id.blank')
    )
  end
end
