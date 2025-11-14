# frozen_string_literal: true

require 'test_helper'

class SortingHelperTest < ActionView::TestCase
  include SortingHelper

  Sort = Struct.new(:name, :dir)
  RansackObj = Struct.new(:sorts)

  Dropdown = Struct.new(:item) do
    def with_item(args)
      self.item = args
    end
  end

  setup do
    @ransack_obj = RansackObj.new([])
  end

  def sort_url(_, sort_string)
    "/sort/#{sort_string.to_s.gsub(' ', '/')}"
  end

  test 'active_sort returns true when field and direction match' do
    @ransack_obj.sorts << Sort.new('email', 'asc')

    assert active_sort(@ransack_obj, :email, :asc)
    assert active_sort(@ransack_obj, 'email', 'asc')
  end

  test 'active_sort returns false when field does not match' do
    @ransack_obj.sorts << Sort.new('email', 'asc')

    assert_not active_sort(@ransack_obj, :name, :asc)
  end

  test 'active_sort returns false when direction does not match' do
    @ransack_obj.sorts << Sort.new('email', 'asc')

    assert_not active_sort(@ransack_obj, :email, :desc)
  end

  test 'active_sort returns false when sorts is empty' do
    assert_not active_sort(@ransack_obj, :email, :asc)
  end

  test 'sorting_item creates dropdown item with correct attributes' do
    dropdown = Dropdown.new
    dropdown.define_singleton_method(:with_item) do |args|
      @item = args
    end

    @ransack_obj.sorts << Sort.new('name', 'asc')

    sorting_item(dropdown, @ransack_obj, :name, :asc)

    expected_label = I18n.t('components.ransack.sort_dropdown_component.sorting.name_asc')
    assert_equal expected_label, dropdown.instance_variable_get(:@item)[:label]
    assert_equal '/sort/name/asc', dropdown.instance_variable_get(:@item)[:url]
    assert_equal :check, dropdown.instance_variable_get(:@item)[:icon_name]
    assert_equal({ turbo: true, turbo_action: 'replace' }, dropdown.instance_variable_get(:@item)[:data])
  end

  test 'sorting_url with direction generates correct URL' do
    assert_equal '/sort/email/asc', sorting_url(@ransack_obj, :email, dir: :asc)
  end

  test 'sorting_url without direction generates correct URL' do
    assert_equal '/sort/email', sorting_url(@ransack_obj, :email)
  end

  test 'aria_sort returns empty hash when column is not sorted' do
    assert_equal({}, aria_sort('email', nil, nil))
    assert_equal({}, aria_sort('email', 'name', 'asc'))
  end

  test 'aria_sort returns ascending for asc direction' do
    expected = { 'aria-sort': 'ascending' }
    assert_equal expected, aria_sort('email', 'email', 'asc')
  end

  test 'aria_sort returns descending for desc direction' do
    expected = { 'aria-sort': 'descending' }
    assert_equal expected, aria_sort('email', 'email', 'desc')
  end
end
