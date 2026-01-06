# frozen_string_literal: true

require 'test_helper'

class FileSelectorTest < ActiveSupport::TestCase
  test 'sorted_files returns files separated by type and sorted by created_at' do
    sample_b = samples(:sampleB)

    sorted_files = sample_b.sorted_files
    assert sorted_files.is_a?(Hash)
    assert_equal 3, sorted_files.length

    assert sorted_files.key?(:singles)
    assert sorted_files.key?(:pe_forward)
    assert sorted_files.key?(:pe_reverse)

    singles_files = sorted_files[:singles]
    pe_forward_files = sorted_files[:pe_forward]
    pe_reverse_files = sorted_files[:pe_reverse]

    assert singles_files.is_a?(Array)
    assert pe_forward_files.is_a?(Array)
    assert pe_reverse_files.is_a?(Array)

    assert_equal 3, singles_files.length
    assert_equal 3, pe_forward_files.length
    assert_equal 3, pe_reverse_files.length

    # Check that files are sorted by created_at
    singles_files.each_cons(2) do |file1, file2|
      assert file1[:created_at] <= file2[:created_at]
    end

    pe_forward_files.each_cons(2) do |file1, file2|
      assert file1[:created_at] <= file2[:created_at]
    end

    pe_reverse_files.each_cons(2) do |file1, file2|
      assert file1[:created_at] <= file2[:created_at]
    end
  end
end
