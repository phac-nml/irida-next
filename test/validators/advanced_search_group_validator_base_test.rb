# frozen_string_literal: true

require 'test_helper'

class AdvancedSearchGroupValidatorBaseTest < ActiveSupport::TestCase
  class DummyAdvancedSearchGroupValidator < AdvancedSearchGroupValidatorBase
    private

    def allowed_fields
      %w[name created_at]
    end

    def date_fields
      %w[created_at]
    end
  end

  class DummyCondition
    include ActiveModel::Validations

    attr_accessor :field, :operator, :value

    def initialize(field:, operator:, value:)
      @field = field
      @operator = operator
      @value = value
    end
  end

  class DummyGroup
    include ActiveModel::Validations

    attr_accessor :conditions

    def initialize(conditions:)
      @conditions = conditions
    end

    def empty?
      conditions.all? do |condition|
        condition.field.blank? && condition.operator.blank? && condition.value.blank?
      end
    end
  end

  class DummyRecord
    include ActiveModel::Validations

    attr_accessor :groups

    validates_with DummyAdvancedSearchGroupValidator

    def initialize(groups:)
      @groups = groups
    end
  end

  test 'allows empty search with single empty group' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: '', operator: '', value: '')])]
    )

    assert record.valid?
  end

  test 'rejects invalid field names and bubbles up group/record errors' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'bad_field', operator: '=', value: 'x')])]
    )

    assert_not record.valid?
    assert record.errors.added?(:groups, :invalid)

    group = record.groups.first
    condition = group.conditions.first

    assert group.errors.added?(:conditions, :invalid)
    assert condition.errors.added?(:field, :not_a_metadata)
  end

  test 'accepts metadata.* fields' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.custom', operator: '=', value: 'x')])]
    )

    assert record.valid?
  end

  test 'validates blank field/operator/value for non-exists operators' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: '', operator: '', value: '')])]
    )

    assert record.valid?, 'single empty group is treated as empty search'

    record2 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: '=', value: '')])]
    )

    assert_not record2.valid?
    condition = record2.groups.first.conditions.first
    assert condition.errors.added?(:value, :blank)
  end

  test 'allows blank value for exists/not_exists operators' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: 'exists', value: '')])]
    )

    assert record.valid?
  end

  test 'treats blank arrays as blank value' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: 'in', value: [nil, ''])])]
    )

    assert_not record.valid?
    condition = record.groups.first.conditions.first
    assert condition.errors.added?(:value, :blank)
  end

  test 'restricts date operators for date fields' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: 'contains', value: 'x')])]
    )

    assert_not record.valid?
    condition = record.groups.first.conditions.first
    assert condition.errors.added?(:operator, :not_a_date_operator)
  end

  test 'validates date format for date fields' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                              value: '2024-13-40')])]
    )

    assert_not record.valid?
    condition = record.groups.first.conditions.first
    assert condition.errors.added?(:value, :not_a_date)

    record2 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                              value: '2024-12-17')])]
    )

    assert record2.valid?
  end

  test 'treats *_date fields as date fields' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.custom_date', operator: 'contains',
                                                              value: 'x')])]
    )

    assert_not record.valid?
    condition = record.groups.first.conditions.first
    assert condition.errors.added?(:operator, :not_a_date_operator)

    record2 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.custom_date', operator: '=',
                                                              value: '2024-99-99')])]
    )

    assert_not record2.valid?
    condition2 = record2.groups.first.conditions.first
    assert condition2.errors.added?(:value, :not_a_date)

    record3 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.custom_date', operator: '=',
                                                              value: '2024-12-17')])]
    )

    assert record3.valid?
  end

  test 'validates numeric values for comparison operators' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.count', operator: '>=', value: 'nope')])]
    )

    assert_not record.valid?
    condition = record.groups.first.conditions.first
    assert condition.errors.added?(:value, :not_a_number)
  end

  test 'enforces unique field conditions except for a valid between pair' do
    record = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [
                                DummyCondition.new(field: 'name', operator: '=', value: 'a'),
                                DummyCondition.new(field: 'name', operator: '!=', value: 'b')
                              ])]
    )

    assert_not record.valid?
    second = record.groups.first.conditions.last
    assert second.errors.added?(:operator, :taken)

    record2 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [
                                DummyCondition.new(field: 'created_at', operator: '>=', value: '2024-01-01'),
                                DummyCondition.new(field: 'created_at', operator: '<=', value: '2024-12-31')
                              ])]
    )

    assert record2.valid?

    record3 = DummyRecord.new(
      groups: [DummyGroup.new(conditions: [
                                DummyCondition.new(field: 'created_at', operator: '>=', value: '2024-01-01'),
                                DummyCondition.new(field: 'created_at', operator: '<=', value: '2024-12-31'),
                                DummyCondition.new(field: 'created_at', operator: '=', value: '2024-06-01')
                              ])]
    )

    assert_not record3.valid?
    third = record3.groups.first.conditions.last
    assert third.errors.added?(:operator, :taken)
  end
end
