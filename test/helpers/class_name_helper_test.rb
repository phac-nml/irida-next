# frozen_string_literal: true

require 'test_helper'

class ClassNameHelperTest < ActionView::TestCase
  include ClassNameHelper

  test 'should combine list of classes' do
    new_classes = class_names('foo', 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with nil' do
    new_classes = class_names('foo', nil, 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with empty string' do
    new_classes = class_names('foo', '', 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with false' do
    new_classes = class_names('foo', false, 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with true' do
    new_classes = class_names('foo', true, 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with empty array' do
    new_classes = class_names('foo', [], 'bar')
    assert_equal 'bar foo', new_classes
  end

  test 'should combine list of classes with array' do
    new_classes = class_names('foo', %w[bar baz], 'qux')
    assert_equal 'bar baz foo qux', new_classes
  end

  test 'should combine hash of classes' do
    new_classes = class_names('foo', bar: true, baz: false, qux: nil)
    assert_equal 'bar foo', new_classes
  end
end
