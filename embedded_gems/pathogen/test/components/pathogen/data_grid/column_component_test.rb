# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module DataGrid
    # Unit tests for ColumnComponent
    class ColumnComponentTest < ActiveSupport::TestCase
      test 'initializes with label' do
        column = ColumnComponent.new(label: 'Name')
        assert_equal 'Name', column.label
      end

      test 'initializes with all options' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: 120, align: :right, sticky: true, sticky_left: 0)
        assert_equal 'ID', column.label
        assert_equal :id, column.key
        assert_equal 120, column.width
        assert_equal :right, column.align
        assert column.sticky
        assert_equal 0, column.sticky_left
      end

      test 'header_cell_attributes returns correct classes' do
        column = ColumnComponent.new(label: 'Name', key: :name)
        attrs = column.header_cell_attributes

        assert_includes attrs[:class], 'pathogen-data-grid__cell'
        assert_includes attrs[:class], 'pathogen-data-grid__cell--header'
      end

      test 'body_cell_attributes returns correct classes' do
        column = ColumnComponent.new(label: 'Name', key: :name)
        attrs = column.body_cell_attributes

        assert_includes attrs[:class], 'pathogen-data-grid__cell'
        assert_includes attrs[:class], 'pathogen-data-grid__cell--body'
      end

      test 'attributes include sticky class when sticky' do
        column = ColumnComponent.new(label: 'ID', key: :id, sticky: true, sticky_left: 0)
        attrs = column.header_cell_attributes

        assert_includes attrs[:class], 'pathogen-data-grid__cell--sticky'
        assert_includes attrs[:style], '--pathogen-data-grid-sticky-left: 0px;'
      end

      test 'attributes include alignment class when align specified' do
        column = ColumnComponent.new(label: 'Amount', key: :amount, align: :right)
        attrs = column.body_cell_attributes

        assert_includes attrs[:class], 'pathogen-data-grid__cell--align-right'
      end

      test 'attributes include width style when width specified' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: '150px')
        attrs = column.header_cell_attributes

        assert_includes attrs[:style], '--pathogen-data-grid-col-width: 150px;'
      end

      test 'render_value uses block when provided' do
        column = ColumnComponent.new(label: 'Name') { |row, _index| row[:name].upcase }
        result = column.render_value({ name: 'test' }, 0)

        assert_equal 'TEST', result
      end

      test 'render_value uses key for hash row' do
        column = ColumnComponent.new(label: 'Name', key: :name)
        result = column.render_value({ name: 'Sample' }, 0)

        assert_equal 'Sample', result
      end

      test 'render_value uses string key for hash row' do
        column = ColumnComponent.new(label: 'Name', key: :name)
        result = column.render_value({ 'name' => 'Sample' }, 0)

        assert_equal 'Sample', result
      end

      test 'render_value uses index for array row' do
        column = ColumnComponent.new(label: 'First')
        result = column.render_value(%w[a b c], 1)

        assert_equal 'b', result
      end

      test 'normalize_width! converts numeric to px string' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: 120)
        column.normalize_width!

        assert_equal '120px', column.width
      end

      test 'normalize_width! preserves string width' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: '10rem')
        column.normalize_width!

        assert_equal '10rem', column.width
      end

      test 'normalize_width! handles blank width' do
        column = ColumnComponent.new(label: 'ID', key: :id)
        column.normalize_width!

        assert_nil column.width
      end

      test 'width_px extracts pixel value' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: '150px')

        assert_equal 150.0, column.width_px
      end

      test 'width_px returns nil for non-px width' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: '10rem')

        assert_nil column.width_px
      end

      test 'width_px handles decimal values' do
        column = ColumnComponent.new(label: 'ID', key: :id, width: '123.5px')

        assert_equal 123.5, column.width_px
      end
    end
  end
end
