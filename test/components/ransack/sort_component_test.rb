# frozen_string_literal: true

require 'test_helper'

module Ransack
  class SortComponentTest < ViewComponent::TestCase
    test 'sort ascending' do
      q = Member.ransack({ s: 'user_email asc' })
      label = 'user_email'
      url = 'http://localhost:3000/bacillus/bacillus-anthracis/outbreak-2022/-/members?q%5Bs%5D=user_email+asc'
      column = :user_email

      render_inline SortComponent.new(
        ransack_obj: q,
        label:,
        url:,
        field: column
      )

      assert_selector "a[href='#{url}']", count: 1
      assert_selector "a##{"sort-#{column}-#{label}".parameterize}", count: 1
      assert_text label
      assert_selector 'svg.arrow-up-icon', count: 1
    end

    test 'sort descending' do
      q = Member.ransack({ s: 'user_email desc' })
      label = 'user_email'
      url = 'http://localhost:3000/bacillus/bacillus-anthracis/outbreak-2022/-/members?q%5Bs%5D=user_email+desc'
      column = :user_email

      render_inline SortComponent.new(
        ransack_obj: q,
        label:,
        url:,
        field: column
      )

      assert_selector "a[href='#{url}']", count: 1
      assert_selector "a##{"sort-#{column}-#{label}".parameterize}", count: 1
      assert_text label
      assert_selector 'svg.arrow-down-icon', count: 1
    end

    test 'parameterizes id when label contains whitespace' do
      q = Member.ransack({ s: 'created_at asc' })
      label = 'Created at'
      url = 'http://localhost:3000/members?q%5Bs%5D=created_at+asc'
      column = :created_at

      render_inline SortComponent.new(
        ransack_obj: q,
        label:,
        url:,
        field: column
      )

      assert_selector 'a#sort-created_at-created-at', count: 1
    end
  end
end
