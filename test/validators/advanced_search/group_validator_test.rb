# frozen_string_literal: true

require 'test_helper'

module AdvancedSearch
  class GroupValidatorTest < ActiveSupport::TestCase
    class DummyGroupValidator < AdvancedSearch::GroupValidator
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

      validates_with DummyGroupValidator

      def initialize(groups:)
        @groups = groups
      end
    end

    test 'allows structurally empty search with no groups' do
      record = DummyRecord.new(groups: [])

      assert record.valid?
    end

    test 'rejects empty search with single empty group' do
      record = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: '', operator: '', value: '')])]
      )

      assert_not record.valid?
      assert record.errors.added?(:base, :invalid)
    end

    test 'rejects structurally empty search with groups but no conditions' do
      record = DummyRecord.new(groups: [DummyGroup.new(conditions: [])])

      assert_not record.valid?
      assert record.errors.added?(:base, :invalid)
    end

    test 'rejects invalid field names and bubbles up group/record errors' do
      record = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'bad_field', operator: '=', value: 'x')])]
      )

      assert_not record.valid?
      assert record.errors.added?(:base, :invalid)

      group = record.groups.first
      condition = group.conditions.first

      assert condition.errors.added?(:field, :not_a_metadata)
    end

    test 'accepts metadata.* fields' do
      record = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.custom', operator: '=', value: 'x')])]
      )

      assert record.valid?
    end

    test 'validates blank field/operator/value for non-exists operators' do
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
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: 'contains',
                                                                value: 'x')])]
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

      record1 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                                value: 'a')])]
      )

      assert_not record1.valid?
      condition1 = record1.groups.first.conditions.first
      assert condition1.errors.added?(:value, :not_a_date)

      record2 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                                value: '2024-12-17')])]
      )

      assert record2.valid?

      Flipper.enable(:advanced_search_metadata_operators)

      record3 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                                value: '2024-13-40')])]
      )

      assert_not record3.valid?
      condition3 = record3.groups.first.conditions.first
      assert condition3.errors.added?(:value, :not_a_date)

      record4 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                                value: 'a')])]
      )

      assert_not record4.valid?
      condition4 = record4.groups.first.conditions.first
      assert condition4.errors.added?(:value, :not_a_date)

      record5 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'created_at', operator: '=',
                                                                value: '2024-12-17')])]
      )

      assert record5.valid?
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
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
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.count', operator: '>=',
                                                                value: 'nope')])]
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
      assert second.errors.added?(:field, :taken)

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
      assert third.errors.added?(:field, :taken)
    end

    test 'validates numeric values for metadata numeric operators' do
      Flipper.enable(:advanced_search_metadata_operators)
      record = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.count', operator: 'numeric_equals',
                                                                value: 'not_a_number')])]
      )

      assert_not record.valid?
      condition = record.groups.first.conditions.first
      assert condition.errors.added?(:value, :not_a_number)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
    end

    test 'validates date values for metadata date operators' do
      Flipper.enable(:advanced_search_metadata_operators)
      record = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.count', operator: 'date_not_equals',
                                                                value: 'not_a_date')])]
      )

      assert_not record.valid?
      condition = record.groups.first.conditions.first
      assert condition.errors.added?(:value, :not_a_date)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
    end

    test 'validates metadata between operators' do
      Flipper.enable(:advanced_search_metadata_operators)

      record1 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [
                                  DummyCondition.new(field: 'metadata.date_of_birth', operator: 'date_less_than_equals',
                                                     value: '2024-01-01'),
                                  DummyCondition.new(field: 'metadata.date_of_birth',
                                                     operator: 'date_greater_than_equals', value: '2024-12-31')
                                ])]
      )

      assert record1.valid?

      record2 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_less_than_equals',
                                                     value: '1'),
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_greater_than_equals',
                                                     value: '100')
                                ])]
      )

      assert record2.valid?

      record3 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_less_than_equals',
                                                     value: '1'),
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_greater_than_equals',
                                                     value: '100'),
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_equals',
                                                     value: '59')
                                ])]
      )

      assert_not record3.valid?
      third = record3.groups.first.conditions.last
      assert third.errors.added?(:field, :taken)

      record4 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [
                                  DummyCondition.new(field: 'metadata.age', operator: 'numeric_less_than_equals',
                                                     value: '1'),
                                  DummyCondition.new(field: 'metadata.age', operator: 'date_greater_than_equals',
                                                     value: '2026-01-01')
                                ])]
      )

      assert_not record4.valid?
      fourth = record4.groups.first.conditions.last
      assert fourth.errors.added?(:field, :taken)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
    end

    test 'operators with advanced_search_disable_standard_operators_for_metadata_in_graphql feature flag enabled' do
      Flipper.enable(:advanced_search_metadata_operators)

      # standard operators still work on metadata field
      record1 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.test_field', operator: '=',
                                                                value: 'x')])]
      )

      assert record1.valid?
      assert_not record1.errors.added?(:base, :invalid)

      # metadata operator works as expected on metadata field
      record2 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.test_field', operator: 'TEXT_EQUALS',
                                                                value: 'x')])]
      )

      assert record2.valid?
      assert_not record2.errors.added?(:base, :invalid)

      # metadata operator cannot be used on standard field
      record3 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: 'TEXT_EQUALS',
                                                                value: 'x')])]
      )

      assert_not record3.valid?
      assert record3.errors.added?(:base, :invalid)
      third = record3.groups.first.conditions.last
      assert third.errors.added?(:operator, :use_non_metadata_operator)

      Flipper.enable(:advanced_search_disable_standard_operators_for_metadata_in_graphql)
      # standard operators cannot be used on metadata field with
      # advanced_search_disable_standard_operators_for_metadata_in_graphql enabled
      record4 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.test_field', operator: '=',
                                                                value: 'x')])]
      )

      assert_not record4.valid?
      assert record4.errors.added?(:base, :invalid)
      fourth = record4.groups.first.conditions.last
      assert fourth.errors.added?(:operator, :use_metadata_operator)

      # metadata operator works as expected on metadata field with
      # advanced_search_disable_standard_operators_for_metadata_in_graphql enabled
      record5 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.test_field', operator: 'TEXT_EQUALS',
                                                                value: 'x')])]
      )

      assert record5.valid?
      assert_not record5.errors.added?(:base, :invalid)

      # metadata operator still cannot be used on standard field with
      # advanced_search_disable_standard_operators_for_metadata_in_graphql enabled
      record6 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: 'TEXT_EQUALS',
                                                                value: 'x')])]
      )

      assert_not record6.valid?
      assert record6.errors.added?(:base, :invalid)
      sixth = record6.groups.first.conditions.last
      assert sixth.errors.added?(:operator, :use_non_metadata_operator)
    ensure
      Flipper.disable(:advanced_search_metadata_operators)
      Flipper.disable(:advanced_search_disable_standard_operators_for_metadata_in_graphql)
    end

    test 'standard operators work as expected with advanced_search_disable_standard_operators_for_metadata_in_graphql enabled but not advanced_search_metadata_operators' do # rubocop:disable Layout/LineLength
      Flipper.enable(:advanced_search_disable_standard_operators_for_metadata_in_graphql)
      # standard operators works on metadata
      record1 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'metadata.test_field', operator: '=',
                                                                value: 'x')])]
      )

      assert record1.valid?
      assert_not record1.errors.added?(:base, :invalid)

      # standard operators works on standard field
      record2 = DummyRecord.new(
        groups: [DummyGroup.new(conditions: [DummyCondition.new(field: 'name', operator: '=',
                                                                value: 'x')])]
      )

      assert record2.valid?
      assert_not record2.errors.added?(:base, :invalid)
    ensure
      Flipper.disable(:advanced_search_disable_standard_operators_for_metadata_in_graphql)
    end
  end
end
