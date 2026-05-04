# frozen_string_literal: true

require 'test_helper'

class DateValidatorTest < ActiveSupport::TestCase
  setup do
    @group = groups(:group_one)
    @user = users(:john_doe)
    @member = users(:user25)
    @group_to_group_link = groups(:group_y)
  end

  test 'member with valid expires_at date' do
    tomorrow = (Time.zone.today + 1.day).strftime('%Y-%m-%d')
    member = create_group_member(tomorrow)

    assert member.valid?
  end

  test 'member with no expires_at input' do
    member = create_group_member('')

    assert member.valid?
  end

  test 'member with valid date format but invalid expires_at date' do
    before_expires_at = (Time.zone.today - 10.days).strftime('%Y-%m-%d')
    member = create_group_member(before_expires_at)

    assert_not member.valid?
    assert_equal(I18n.t('common.date.errors.invalid_min_date'),
                 member.errors[:expires_at].first)
  end

  test 'member expires_at with parseable non-YYYY-MM-DD format' do
    invalid_date_format = (Time.zone.today - 10.days).strftime('%d-%m-%Y')
    member = create_group_member(invalid_date_format)

    assert_not member.valid?
    assert_equal(I18n.t('common.date.errors.invalid_min_date'),
                 member.errors[:expires_at].first)
  end

  test 'member expires_at with invalid input' do
    invalid_input = 'this_is_an_invalid_input'
    member = create_group_member(invalid_input)

    assert_not member.valid?
    assert_equal(I18n.t('common.date.errors.invalid_input'),
                 member.errors[:expires_at].first)
  end

  test 'group link with valid expires_at date' do
    tomorrow = (Time.zone.today + 1.day).strftime('%Y-%m-%d')
    group_link = create_group_link(tomorrow)

    assert group_link.valid?
  end

  test 'group link with no expires_at input' do
    group_link = create_group_link('')

    assert group_link.valid?
  end

  test 'group link with valid date format but invalid expires_at date' do
    before_expires_at = (Time.zone.today - 10.days).strftime('%Y-%m-%d')
    group_link = create_group_link(before_expires_at)

    assert_not group_link.valid?
    assert_equal(I18n.t('common.date.errors.invalid_min_date'),
                 group_link.errors[:expires_at].first)
  end

  test 'group link expires_at with parseable non-YYYY-MM-DD format' do
    invalid_date_format = (Time.zone.today - 10.days).strftime('%d-%m-%Y')
    group_link = create_group_link(invalid_date_format)

    assert_not group_link.valid?
    assert_equal(I18n.t('common.date.errors.invalid_min_date'),
                 group_link.errors[:expires_at].first)
  end

  test 'group link expires_at with invalid input' do
    invalid_input = 'this_is_an_invalid_input'
    group_link = create_group_link(invalid_input)

    assert_not group_link.valid?
    assert_equal(I18n.t('common.date.errors.invalid_input'),
                 group_link.errors[:expires_at].first)
  end

  test 'personal access token with cast expires_at date' do
    personal_access_token = PersonalAccessToken.new(
      name: 'Rotated token',
      scopes: %w[api],
      expires_at: Time.zone.today + 1.day,
      user: @user
    )

    assert personal_access_token.valid?
  end

  private

  def create_group_member(expires_at_date)
    Member.new(
      access_level: 20,
      namespace_id: @group.id,
      expires_at: expires_at_date,
      created_by: @user,
      user_id: @member.id
    )
  end

  def create_group_link(expires_at_date)
    NamespaceGroupLink.new(
      group_access_level: 20,
      expires_at: expires_at_date,
      group_id: @group_to_group_link.id,
      namespace_id: @group.id,
      namespace_type: 'Group'
    )
  end
end
