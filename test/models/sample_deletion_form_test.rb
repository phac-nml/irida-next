# frozen_string_literal: true

require 'test_helper'

class SampleDeletionFormTest < ActiveSupport::TestCase
  test 'is invalid when reason exceeds maximum length' do
    form = SampleDeletionForm.new(reason: 'a' * 501)

    assert_not form.valid?
    assert_includes form.errors.details[:reason].pluck(:error), :too_long
  end

  test 'is invalid when raw reason exceeds maximum length with repeated whitespace' do
    form = SampleDeletionForm.new(reason: ('a    ' * 130))

    assert_not form.valid?
    assert_includes form.errors.details[:reason].pluck(:error), :too_long
  end

  test 'strips leading and trailing whitespace from reason' do
    form = SampleDeletionForm.new(reason: '  remove me  ')

    assert_predicate form, :valid?
    assert_equal 'remove me', form.reason
  end
end
