# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module DataTable
    class ColumnComponentTest < ViewComponentTestCase
      test 'initializes with title and block' do
        component = Viral::DataTable::ColumnComponent.new('Test Column') { |row| row[:name] }

        assert_equal 'Test Column', component.title
      end

      test 'content_for returns block result when called with row data' do
        test_row = { name: 'John Doe', email: 'john@example.com' }
        component = Viral::DataTable::ColumnComponent.new('Name') { |row| row[:name] }

        result = component.content_for(test_row)

        assert_equal 'John Doe', result
      end

      test 'header_cell_arguments includes default classes' do
        component = Viral::DataTable::ColumnComponent.new('Column') { |row| row[:value] }

        args = component.header_cell_arguments

        assert_includes args[:classes], 'px-3'
        assert_includes args[:classes], 'py-3'
        assert_includes args[:classes], 'bg-slate-100'
        assert_includes args[:classes], 'dark:bg-slate-900'
        assert_includes args[:classes], 'uppercase'
      end

      test 'body_cell_arguments includes padding by default' do
        component = Viral::DataTable::ColumnComponent.new('Column') { |row| row[:value] }

        args = component.body_cell_arguments

        assert_includes args[:classes], 'py-3'
        assert_includes args[:classes], 'px-3'
      end

      test 'body_cell_arguments removes padding when padding is false' do
        component = Viral::DataTable::ColumnComponent.new('Column', padding: false) { |row| row[:value] }

        args = component.body_cell_arguments

        # When padding is false, the padding classes should not be present
        assert_not_includes args[:classes], 'py-3'
        assert_not_includes args[:classes], 'px-3'
      end

      test 'header_cell_arguments includes sticky classes when sticky_key is provided' do
        component = Viral::DataTable::ColumnComponent.new('Column', sticky_key: :left) { |row| row[:value] }

        args = component.header_cell_arguments

        assert_includes args[:classes], '@2xl:sticky'
        assert_includes args[:classes], 'left-0'
        assert_includes args[:classes], 'z-10'
      end

      test 'body_cell_arguments includes sticky classes when sticky_key is provided' do
        component = Viral::DataTable::ColumnComponent.new('Column', sticky_key: :right) { |row| row[:value] }

        args = component.body_cell_arguments

        assert_includes args[:classes], '@4xl:sticky'
        assert_includes args[:classes], 'right-0'
      end

      test 'supports custom classes in system_arguments' do
        component = Viral::DataTable::ColumnComponent.new('Column', classes: 'custom-class') { |row| row[:value] }

        header_args = component.header_cell_arguments
        body_args = component.body_cell_arguments

        assert_includes header_args[:classes], 'custom-class'
        assert_includes body_args[:classes], 'custom-class'
      end

      test 'handles complex block logic' do
        test_row = { first_name: 'Jane', last_name: 'Smith', active: true }
        component = Viral::DataTable::ColumnComponent.new('Full Name') do |row|
          if row[:active]
            "#{row[:first_name]} #{row[:last_name]} (Active)"
          else
            "#{row[:first_name]} #{row[:last_name]}"
          end
        end

        result = component.content_for(test_row)

        assert_equal 'Jane Smith (Active)', result
      end
    end
  end
end
