# frozen_string_literal: true

require 'test_helper'

class NamespacePathValidatorTest < ActiveSupport::TestCase
  class ValidationRecord
    include ActiveModel::Model

    attr_accessor :full_path

    def build_full_path
      full_path
    end
  end

  setup do
    @validator = NamespacePathValidator.new(attributes: [:path])
  end

  test 'accepts a blank path' do
    record = validation_record(nil)

    validate(record, '')

    assert_empty record.errors
  end

  test 'rejects a path with an invalid format' do
    record = validation_record('bad path')

    validate(record, 'bad path')

    assert record.errors.added?(:path, :invalid_format)
  end

  test 'accepts a valid root namespace path' do
    record = validation_record('project-1')

    validate(record, 'project-1')

    assert_empty record.errors
  end

  test 'accepts a valid nested namespace path' do
    record = validation_record('group-1/project-1')

    validate(record, 'project-1')

    assert_empty record.errors
  end

  test 'does not validate a reserved path as available' do
    record = validation_record('api')

    validate(record, 'api')

    assert record.errors.added?(:path, :reserved_value, value: 'api')
  end

  test 'skips reserved path validation when the full path is unavailable' do
    record = validation_record(nil)

    validate(record, 'api')

    assert_empty record.errors
  end

  test 'exposes the namespace path regular expressions' do
    assert_match NamespacePathValidator.format_regex, 'project-1'
    assert_match NamespacePathValidator.path_regex, 'group-1/project-1/'
    assert NamespacePathValidator.valid_path?('group-1/project-1')
    assert_not NamespacePathValidator.valid_path?('api')
  end

  test 'rejects namespace paths with leading or trailing slashes' do
    assert_not NamespacePathValidator.valid_path?('/group-1/project-1')
    assert_not NamespacePathValidator.valid_path?('group-1/project-1/')
  end

  test 'rejects namespace paths with unsupported characters' do
    assert_not NamespacePathValidator.valid_path?('group-1/project@1')
  end

  private

  def validation_record(full_path)
    ValidationRecord.new(full_path:)
  end

  def validate(record, path)
    @validator.validate_each(record, :path, path)
  end
end
