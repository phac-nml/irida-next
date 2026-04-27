# frozen_string_literal: true

require 'test_helper'

class AdvancedSearch::V2::FieldConfigurationTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  test '.allowed_fields returns core field names' do
    fields = AdvancedSearch::V2::FieldConfiguration.allowed_fields
    assert_includes fields, 'name'
    assert_includes fields, 'puid'
    assert_includes fields, 'created_at'
    assert_includes fields, 'updated_at'
    assert_includes fields, 'attachments_updated_at'
  end

  test '.valid_field? returns true for core fields' do
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('name')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('puid')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('created_at')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('updated_at')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('attachments_updated_at')
  end

  test '.valid_field? returns true for metadata.anything' do
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('metadata.province')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('metadata.country')
    assert AdvancedSearch::V2::FieldConfiguration.valid_field?('metadata.any_key')
  end

  test '.valid_field? returns false for invalid field' do
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_field?('invalid_field')
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_field?('description')
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_field?('')
  end

  test '.valid_field? returns false for non-string fields' do
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_field?(['name'])
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_field?({ name: 'sample' })
  end

  test '.operators_for string field returns string operators' do
    ops = AdvancedSearch::V2::FieldConfiguration.operators_for('name')
    assert_includes ops, '='
    assert_includes ops, '!='
    assert_includes ops, 'contains'
    assert_includes ops, 'not_contains'
    assert_includes ops, 'in'
    assert_includes ops, 'not_in'
    assert_includes ops, 'exists'
    assert_includes ops, 'not_exists'
  end

  test '.operators_for date field returns date operators' do
    ops = AdvancedSearch::V2::FieldConfiguration.operators_for('created_at')
    assert_includes ops, '='
    assert_includes ops, '!='
    assert_includes ops, '<='
    assert_includes ops, '>='
    assert_includes ops, 'exists'
    assert_includes ops, 'not_exists'
    assert_not_includes ops, 'contains'
    assert_not_includes ops, 'in'
  end

  test '.operators_for metadata field returns metadata operators' do
    ops = AdvancedSearch::V2::FieldConfiguration.operators_for('metadata.province')
    assert_includes ops, '='
    assert_includes ops, 'contains'
    assert_includes ops, 'in'
    assert_not_includes ops, '>='
  end

  test '.valid_operator? returns false when operator not supported for field' do
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_operator?('name', '>=')
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_operator?('name', '<=')
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_operator?('created_at', 'contains')
    assert_not AdvancedSearch::V2::FieldConfiguration.valid_operator?(['name'], '=')
  end

  test '.valid_operator? returns true when operator supported for field' do
    assert AdvancedSearch::V2::FieldConfiguration.valid_operator?('name', '=')
    assert AdvancedSearch::V2::FieldConfiguration.valid_operator?('created_at', '>=')
    assert AdvancedSearch::V2::FieldConfiguration.valid_operator?('metadata.x', 'contains')
  end
end
