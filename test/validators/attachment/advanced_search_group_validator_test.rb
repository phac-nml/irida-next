# frozen_string_literal: true

require 'test_helper'

class Attachment::AdvancedSearchGroupValidatorTest < ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  test 'validates valid Attachment fields' do
    query = create_query_with_condition('id', '=', 'test')
    assert query.valid?

    query = create_query_with_condition('filename', 'contains', 'test.fastq')
    assert query.valid?

    query = create_query_with_condition('byte_size', '>=', '10')
    assert query.valid?
  end

  test 'validates metadata field pattern' do
    query = create_query_with_condition('metadata.type', '=', 'assembly')
    assert query.valid?

    query = create_query_with_condition('metadata.custom_field', 'contains', 'value')
    assert query.valid?
  end

  test 'rejects invalid field names' do
    query = create_query_with_condition('invalid_field', '=', 'value')
    assert_not query.valid?
    assert query.groups[0].conditions[0].errors[:field].any?
  end

  test 'restricts operators for date fields' do
    query = create_query_with_condition('created_at', 'contains', 'value')
    assert_not query.valid?

    query = create_query_with_condition('created_at', '=', '2024-01-01')
    assert query.valid?
  end

  test 'validates date format for date fields' do
    query = create_query_with_condition('created_at', '=', 'invalid-date')
    assert_not query.valid?
    assert query.groups[0].conditions[0].errors[:value].any?

    query = create_query_with_condition('created_at', '=', '2024-01-01')
    assert query.valid?
  end

  test 'allows empty search with empty groups' do
    query = Attachment::Query.new(groups: [])
    assert query.valid?
  end

  private

  def create_query_with_condition(field, operator, value)
    Attachment::Query.new(
      groups: [Attachment::SearchGroup.new(
        conditions: [Attachment::SearchCondition.new(field:, operator:, value:)]
      )]
    )
  end
end
