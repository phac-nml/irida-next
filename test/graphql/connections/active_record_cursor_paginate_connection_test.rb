# frozen_string_literal: true

require 'test_helper'

class ActiveRecordCursorPaginateConnectionTest < ActiveSupport::TestCase
  test 'raises error when first is not provided but last and after are' do
    assert_raises GraphQL::ExecutionError do
      Connections::ActiveRecordCursorPaginateConnection.new([], field: 'items', first: nil, after: 'cursor',
                                                                max_page_size: 25, default_page_size: 10, last: 5)
    end
  end

  test 'raises error when last is not provided but first and before are' do
    assert_raises GraphQL::ExecutionError do
      Connections::ActiveRecordCursorPaginateConnection.new([], field: 'items', first: 5, before: 'cursor',
                                                                max_page_size: 25, default_page_size: 10, last: nil)
    end
  end
end
