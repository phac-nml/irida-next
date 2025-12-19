# frozen_string_literal: true

require 'test_helper'

class ActiveRecordCursorPaginateConnectionTest < ActiveSupport::TestCase
  OrderByArgument = Struct.new(:field, :direction)

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

  test 'cursor_for returns correct cursor' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    cursor = connection.cursor_for(items.first)
    assert_equal Sample.all.cursor_paginate(limit: 1, order: { created_at: :asc }).fetch.cursor_for(items.first),
                 cursor
  end

  test 'has_previous_page returns false when there is no previous page' do
    items = Sample.none
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert_not connection.has_previous_page
  end

  test 'has_next_page returns false when there is no next page' do
    items = Sample.none
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', last: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert_not connection.has_next_page
  end

  test 'has_previous_page returns true when there is a previous page' do
    items = Sample.order(created_at: :asc)
    cursor = items.cursor_paginate(limit: 5, order: { created_at: :asc }).fetch.cursors.last
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5, after: cursor,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert connection.has_previous_page
  end

  test 'has_next_page returns true when there is a next page' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert connection.has_next_page
  end

  test 'nodes returns correct records when passing first without a cursor' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    expected_records = Sample.order(created_at: :asc).limit(5).to_a
    assert_equal expected_records, connection.nodes
  end

  test 'nodes returns correct records when passing last without a cursor' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: nil, last: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    expected_records = Sample.order(created_at: :desc, id: :asc).first(5).to_a.reverse
    assert_equal expected_records, connection.nodes
  end

  test 'nodes returns correct records when passing first with after cursor' do
    items = Sample.order(created_at: :asc)
    paginator = items.cursor_paginate(limit: 5, order: { created_at: :asc })
    first_page = paginator.fetch
    after_cursor = first_page.cursors.last

    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5, after: after_cursor,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    expected_records = Sample.order(created_at: :asc).offset(5).limit(5).to_a
    assert_equal expected_records, connection.nodes
  end

  test 'nodes returns correct records when passing last with before cursor' do
    items = Sample.order(created_at: :asc)
    paginator = items.cursor_paginate(limit: 5, order: { created_at: :asc })
    paginator.fetch # skip first page
    second_page = paginator.fetch
    before_cursor = second_page.cursors.first

    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: nil, last: 5, before: before_cursor,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    expected_records = Sample.order(created_at: :asc, id: :asc).first(5).to_a
    assert_equal expected_records, connection.nodes
  end

  test 'sets order based on existing order from passed in scope' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5,
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    expected_records = Sample.order(created_at: :asc).limit(5).to_a
    assert_equal expected_records, connection.nodes
  end

  test 'after returns nil when after is "null"' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5, after: 'null',
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert_nil connection.after
  end

  test 'before returns nil when before is "null"' do
    items = Sample.order(created_at: :asc)
    connection = Connections::ActiveRecordCursorPaginateConnection.new(
      items, field: 'items', first: 5, before: 'null',
             max_page_size: 25, default_page_size: 10,
             arguments: {}
    )

    assert_nil connection.before
  end
end
