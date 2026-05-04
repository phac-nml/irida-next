# frozen_string_literal: true

# Validator for date inputs. Currently evaluates expires_at for member, group link, and personal access token models.
class DateValidator < ActiveModel::EachValidator
  class DateValidatorError < StandardError
  end

  def validate_each(record, attribute, value)
    return true unless attribute == :expires_at # currently only handles :expires_at

    # Value is only present when the input can be coerced into a date.
    if value.blank?
      record.errors.add(:expires_at, I18n.t('common.date.errors.invalid_input'))
      return false
    end

    # validate if date input is later than today's date
    raise DateValidatorError, I18n.t('common.date.errors.invalid_min_date') if value < Time.zone.today

    true
  rescue DateValidator::DateValidatorError => e
    record.errors.add(:expires_at, e.message)
    false
  end
end
