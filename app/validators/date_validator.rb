# frozen_string_literal: true

# Validator for date inputs. Currently evaluates expires_at for member, namespace_group_link,
# and personal access token models.
class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true unless attribute == :expires_at # currently only handles :expires_at

    raw_value = record.read_attribute_before_type_cast(:expires_at)
    return true if raw_value.blank? && (expiration_required?(record) == false)

    # Value is only present when the input can be coerced into a date.
    if value.blank?
      record.errors.add(:expires_at, I18n.t('common.date.errors.invalid_input'))
      false
    else
      # validate if date input is later than today's date
      validate_greater_than(record, value) if options[:greater_than].present?

      # validate if date input is within the maximum allowed lifetime
      validate_less_than(record, value) if options[:less_than].present?
    end
  end

  private

  def expiration_required?(record)
    expiration_value = resolve_value(record, options[:less_than]) if options[:less_than].present?
    expiration_required = expiration_value.present? || false
    return false if expiration_required == false

    true
  end

  def option_as_date(record, option_value)
    parse_as_date(record, resolve_value(record, option_value))
  end

  def parse_as_date(record, raw_value)
    case raw_value
    when Date
      raw_value
    when DateTime, ActiveSupport::TimeWithZone
      raw_value.to_date
    when nil
      nil
    end
  rescue ArgumentError
    record.errors.add(:expires_at, 'must be a date or datetime object')
    nil
  end

  def resolve_value(record, value) # rubocop:disable Metrics/MethodLength
    case value
    when Proc
      if value.arity == 0 # rubocop:disable Style/NumericPredicate
        value.call
      else
        value.call(record)
      end
    when Symbol
      record.send(value)
    else
      if value.respond_to?(:call)
        value.call(record)
      else
        value
      end
    end
  end

  def validate_greater_than(record, value)
    min_date = option_as_date(record, options[:greater_than])

    return true if min_date.nil?
    return unless value <= min_date

    record.errors.add(:expires_at, :date_greater_than,
                      date: min_date)
  end

  def validate_less_than(record, value)
    max_date = option_as_date(record, options[:less_than])

    return true if max_date.nil?
    return unless value >= max_date

    record.errors.add(:expires_at, :date_less_than,
                      date: max_date)
  end
end
