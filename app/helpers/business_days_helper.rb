# frozen_string_literal: true

# Helper that adds business days to a given date
module BusinessDaysHelper
  def add_business_days(date, business_days_to_add)
    expiry = business_days_to_add.business_days.after(date)
    # Because the Holidays gem does not have great filters for specific federal holidays, we have to filter
    # with the BC, ON, and CAN holidays to get two lists, observed and informal holidays. However the lists also
    # contain many non-Federal holidays, so we need a hard-coded list of holidays, and filter through them to check
    # for matches to add extra days to our expiry.
    observed_holidays = ["New Year's Day", 'Good Friday', 'Victoria Day', 'Canada Day', 'Labour Day',
                         'National Day for Truth and Reconciliation', 'Thanksgiving',
                         'Remembrance Day', 'Christmas Day', 'Boxing Day']
    informal_holidays = ['Easter Monday', 'Civic Holiday']

    check_formal_holidays = Holidays.between(Date.current, expiry, %i[ca_bc ca_on ca], :observed)
    check_informal_holidays = Holidays.between(Date.current, expiry, %i[ca_bc ca_on ca], :informal)

    extra_days = 0
    extra_days += add_holidays(check_formal_holidays, observed_holidays) if check_formal_holidays.any?
    extra_days += add_holidays(check_informal_holidays, informal_holidays) if check_informal_holidays.any?
    expiry = extra_days.business_days.after(expiry) if extra_days.positive?
    expiry
  end

  private

  def add_holidays(days_to_check, holidays)
    extra_days = 0
    holidays.each do |holiday|
      if days_to_check.any? { |h| h[:name] == holiday }
        extra_days += 1
        next
      end
    end
    extra_days
  end
end
