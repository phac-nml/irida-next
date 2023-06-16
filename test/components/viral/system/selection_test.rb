# frozen_string_literal: true

require 'application_system_test_case'

module System
  class SelectionTest < ApplicationSystemTestCase
    test 'default' do
      visit('rails/view_components/selection/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        check 'item0'
        uncheck 'item1'
        check 'item2'
      end
      visit('rails/view_components/selection/default')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert find_field('item0').checked?
        assert_not find_field('item1').checked?
        assert find_field('item2').checked?
      end
    end

    test 'with a storage key' do
      visit('rails/view_components/selection/with_a_storage_key')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        check 'item0'
        uncheck 'item1'
        check 'item2'
      end
      visit('rails/view_components/selection/with_a_storage_key')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert find_field('item0').checked?
        assert_not find_field('item1').checked?
        assert find_field('item2').checked?
      end
    end

    test 'with a table' do
      visit('rails/view_components/selection/within_a_table')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        uncheck 'row0'
        check 'row1'
        uncheck 'row2'
      end
      visit('rails/view_components/selection/within_a_table')
      within('.Viral-Preview > [data-controller-connected="true"]') do
        assert_not find_field('row0').checked?
        assert find_field('row1').checked?
        assert_not find_field('row2').checked?
      end
    end
  end
end
