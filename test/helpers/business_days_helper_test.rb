# frozen_string_literal: true

require 'test_helper'

class BusinessDaysHelperTest < ActionView::TestCase
  include BusinessDaysHelper

  test 'test adding 3 business days to each day of the week excluding holidays' do
    # Monday -> Thursday
    test_date = Date.new(2024, 3, 11)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 3, 14), add_business_days(test_date, 3)
    end
    # Tuesday -> Friday
    test_date = Date.new(2024, 3, 12)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 3, 15), add_business_days(test_date, 3)
    end
    # Wednesday -> Monday
    test_date = Date.new(2024, 3, 13)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 3, 18), add_business_days(test_date, 3)
    end
    # Thursday -> Tuesday
    test_date = Date.new(2024, 3, 14)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 3, 19), add_business_days(test_date, 3)
    end
    # Friday -> Wednesday
    test_date = Date.new(2024, 3, 15)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 3, 20), add_business_days(test_date, 3)
    end
  end

  test 'test add business days that include federal holidays' do
    # New Year's Day
    test_date = Date.new(2023, 12, 29)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 1, 5), add_business_days(test_date, 4)
    end
    # Good Friday and Easter Monday
    test_date = Date.new(2024, 3, 28)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 4, 4), add_business_days(test_date, 3)
    end
    # Victoria Day
    test_date = Date.new(2022, 5, 19)
    Timecop.travel(test_date) do
      assert_equal Date.new(2022, 5, 25), add_business_days(test_date, 3)
    end
    # Canada Day
    test_date = Date.new(2024, 6, 28)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 7, 8), add_business_days(test_date, 5)
    end
    # Civic Day
    test_date = Date.new(2019, 8, 2)
    Timecop.travel(test_date) do
      assert_equal Date.new(2019, 8, 8), add_business_days(test_date, 3)
    end
    # Labour Day
    test_date = Date.new(2020, 9, 3)
    Timecop.travel(test_date) do
      assert_equal Date.new(2020, 9, 9), add_business_days(test_date, 3)
    end
    # National Day for Truth and Reconciliation
    test_date = Date.new(2024, 9, 27)
    Timecop.travel(test_date) do
      assert_equal Date.new(2024, 10, 3), add_business_days(test_date, 3)
    end
    # Thanksgiving
    test_date = Date.new(2022, 10, 7)
    Timecop.travel(test_date) do
      assert_equal Date.new(2022, 10, 13), add_business_days(test_date, 3)
    end
    # In lieu - Remembrance day on weekend
    test_date = Date.new(2023, 11, 9)
    Timecop.travel(test_date) do
      assert_equal Date.new(2023, 11, 15), add_business_days(test_date, 3)
    end
    # In lieu - Christmas and Boxing Day occuring on Sat and Sun, respectively and New Year's
    test_date = Date.new(2021, 12, 24)
    Timecop.travel(test_date) do
      assert_equal Date.new(2022, 1, 6), add_business_days(test_date, 6)
    end
  end
end
