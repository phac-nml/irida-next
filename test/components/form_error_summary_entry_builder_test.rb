# frozen_string_literal: true

require 'test_helper'

class FormErrorSummaryEntryBuilderRegexTest < ActiveSupport::TestCase
  test 'field id attribute path regexp matches valid indexed nested attributes' do
    regexp = FormErrorSummaryEntryBuilder::FIELD_ID_ATTRIBUTE_PATH_REGEXP

    assert_match regexp, 'members_attributes[0].email'
    assert_match regexp, 'members_attributes[0].widgets_attributes[1].name'
    assert_match regexp, 'members_attributes[0].email_attributes'
    assert_match regexp, 'members_attributes[0].email_attributes.blah_attributes'
    assert_match regexp, 'foo_attributes.bar_attributes.baz'
    assert_match regexp, 'foo_attributes[2].bar'
  end

  test 'field id attribute path regexp rejects invalid patterns' do
    regexp = FormErrorSummaryEntryBuilder::FIELD_ID_ATTRIBUTE_PATH_REGEXP

    assert_no_match regexp, 'members[0].email'
    assert_no_match regexp, 'members_attributes.email'
    assert_no_match regexp, 'members_attributes[0][1].email'
    assert_no_match regexp, 'members_attributes[0].email[1]'
  end

  test 'field id parts generation returns expected segments for valid attribute paths' do
    builder = build_form_builder('user', build_user)
    entry_builder = FormErrorSummaryEntryBuilder.new(builder: builder)

    assert_equal %w[members_attributes 0 email], entry_builder.send(:field_id_parts_for, 'members_attributes[0].email')
    assert_equal %w[members_attributes 0 widgets_attributes 1 name],
                 entry_builder.send(:field_id_parts_for, 'members_attributes[0].widgets_attributes[1].name')
    assert_equal %w[members_attributes 0 email_attributes],
                 entry_builder.send(:field_id_parts_for, 'members_attributes[0].email_attributes')
  end

  test 'field id parts generation falls back to raw attribute for invalid paths' do
    builder = build_form_builder('user', build_user)
    entry_builder = FormErrorSummaryEntryBuilder.new(builder: builder)

    assert_equal ['members[0].email'], entry_builder.send(:field_id_parts_for, 'members[0].email')
  end

  private

  def build_form_builder(object_name, object)
    template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    ActionView::Helpers::FormBuilder.new(object_name, object, template, {})
  end

  def build_user
    User.new(
      email: 'test@example.com',
      first_name: 'Ada',
      last_name: 'Lovelace',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      locale: I18n.default_locale.to_s
    )
  end
end
