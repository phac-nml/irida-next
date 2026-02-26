# frozen_string_literal: true

require 'test_helper'

module Pagination
  class ActiveRecordCursorOrderingTest < ActiveSupport::TestCase
    test 'resolves joined-table attribute to qualified column string' do
      order = Sample.joins(:project).order(Project.arel_table[:id].asc).order_values.first

      resolved = ActiveRecordCursorOrdering.send(:resolve_order_expression, order, Sample.arel_table)

      assert_equal 'projects.id', resolved
    end

    test 'returns joined-table columns as strings in order map' do
      scope = Sample.joins(:project).order(Project.arel_table[:id].asc, Sample.arel_table[:id].desc)

      order_map = ActiveRecordCursorOrdering.order(scope) { |direction| direction }

      assert_equal :asc, order_map['projects.id']

      sample_id_key = order_map.keys.find { |key| key.to_s == 'id' }
      assert_not_nil sample_id_key
      assert_equal :desc, order_map[sample_id_key]
    end
  end
end
