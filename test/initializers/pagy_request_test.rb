# frozen_string_literal: true

require 'test_helper'

class PagyAssignAndCheckTest < ActiveSupport::TestCase
  test 'assign_and_check accepts valid integer string' do
    # Valid integer string should work
    pagy = Pagy::Offset.new(count: 100, page: 1, limit: 20)

    assert_equal 20, pagy.limit
  end

  test 'assign_and_check accepts every limit dropdown option' do
    Viral::Pagy::LimitComponent::LIMITS.each do |limit|
      pagy = Pagy::Offset.new(count: 100, page: 1, limit:)

      assert_equal limit, pagy.limit
    end
  end

  test 'assign_and_check rejects a clean string limit not in the dropdown options' do
    # 30 converts cleanly but is not one of Viral::Pagy::LimitComponent::LIMITS
    assert_raises(Pagy::LimitError) do
      Pagy::Offset.new(count: 100, page: 1, limit: '30')
    end
  end

  test 'assign_and_check accepts programmatic integer limits outside the dropdown options' do
    pagy = Pagy::Offset.new(count: 100, page: 1, limit: 5)

    assert_equal 5, pagy.limit
  end

  test 'assign_and_check rejects invalid limit like 50abc' do
    # Invalid limit with non-numeric suffix should raise Pagy::LimitError
    assert_raises(Pagy::LimitError) do
      Pagy::Offset.new(count: 100, page: 1, limit: '50abc')
    end
  end

  test 'invalid limit raises Pagy::LimitError which is a subclass of Pagy::OptionError' do
    # Ensure LimitError is caught by OptionError rescue handlers
    assert Pagy::LimitError < Pagy::OptionError

    error = assert_raises(Pagy::LimitError) do
      Pagy::Offset.new(count: 100, page: 1, limit: '50abc')
    end

    assert_match(/one of: #{Viral::Pagy::LimitComponent::LIMITS.join(', ')}/, error.message)
  end

  test 'assign_and_check rejects negative values' do
    # Negative values should raise OptionError
    assert_raises(Pagy::OptionError) do
      Pagy::Offset.new(count: 100, page: 1, limit: -5)
    end
  end

  test 'assign_and_check rejects zero limit' do
    # Zero limit should raise OptionError (must be >= 1)
    assert_raises(Pagy::OptionError) do
      Pagy::Offset.new(count: 100, page: 1, limit: 0)
    end
  end

  test 'assign_and_check accepts valid page as integer string' do
    # Valid page as string should work
    pagy = Pagy::Offset.new(count: 100, page: '2', limit: 20)

    assert_equal 2, pagy.page
  end

  test 'assign_and_check passes page through to native Pagy behavior (e.g. "2abc" silently becomes 2)' do
    # Only :limit is validated by our override; other options (e.g. :page) pass through to
    # Pagy's native assign_and_check via super, which silently truncates "2abc" to 2.
    pagy = Pagy::Offset.new(count: 100, page: '2abc', limit: 20)

    assert_equal 2, pagy.page
  end

  test 'PagyAssignAndCheckOverride is prepended to Pagy' do
    assert Pagy.ancestors.include?(PagyAssignAndCheckOverride),
           'PagyAssignAndCheckOverride should be in Pagy ancestors'
  end
end
