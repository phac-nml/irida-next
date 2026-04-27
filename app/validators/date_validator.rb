# frozen_string_literal: true

# Validator for date inputs. Currently evaluates expires_at for the member and group_link models
class DateValidator < ActiveModel::EachValidator
  class DateValidatorError < StandardError
  end

  def validate_each(record, attribute, value) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    return true unless attribute == :expires_at # currently only handles :expires_at

    # grab input prior to it be casted as datetime
    expires_at_value = record.read_attribute_before_type_cast(attribute).to_s

    # validate if input match any valid date input (YYYY-MM-DD, DD-MM-YYYY, etc.)
    raise DateValidatorError, I18n.t('common.date.errors.invalid_input') if value.nil?

    # validate if input matched our expected date input (YYYY-MM-DD)
    unless expires_at_value.match?(/\A\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\z/)
      raise DateValidatorError,
            I18n.t('common.date.errors.invalid_format')
    end

    # validate if date input is later than today's date
    raise DateValidatorError, I18n.t('common.date.errors.invalid_min_date') if value < Time.zone.today

    if Irida::CurrentSettings.require_personal_access_token_expiry? &&
       value > (Time.current + Irida::CurrentSettings.max_personal_access_token_lifetime_in_days)
      raise DateValidatorError,
            I18n.t('common.date.errors.invalid_max_date')
    end

    true
  rescue DateValidator::DateValidatorError => e
    record.errors.add(:expires_at, e.message)
    false
  end
end
