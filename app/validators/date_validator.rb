# frozen_string_literal: true

# Validator for date inputs. Currently evaluates expires_at for member, group link, and personal access token models.
class DateValidator < ActiveModel::EachValidator
  class DateValidatorError < StandardError
  end

  def validate_each(record, attribute, value)
    return true unless attribute == :expires_at # currently only handles :expires_at

    expires_at_value = record.read_attribute_before_type_cast(attribute) # grab input prior to it be casted as datetime

    # validate if input match any valid date input (YYYY-MM-DD, DD-MM-YYYY, etc.)
    raise DateValidatorError, I18n.t('common.date.errors.invalid_input') if value.nil?

    # validate if input matched our expected date input (YYYY-MM-DD)
    if expires_at_value.is_a?(String) &&
       !expires_at_value.match?(/\A\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\z/)
      raise DateValidatorError,
            I18n.t('common.date.errors.invalid_format')
    end

    # validate if date input is later than today's date
    raise DateValidatorError, I18n.t('common.date.errors.invalid_min_date') if value < Time.zone.today

    true
  rescue DateValidator::DateValidatorError => e
    record.errors.add(:expires_at, e.message)
    false
  end
end
