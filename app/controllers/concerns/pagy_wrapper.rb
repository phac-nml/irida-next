# frozen_string_literal: true

# Wrapper around pagy(...) and query#results(...) that sanitizes the raw
# :limit/:page params first, since both ultimately rely on String#to_i, which
# silently truncates malformed input (e.g. "25abc" => 25) instead of raising.
#
# Also usable from non-controller objects (e.g. Query objects) as long as they
# always pass explicit :limit/:page values, since `params` is only consulted
# for whichever of those two keys the caller left nil.
module PagyWrapper
  extend ActiveSupport::Concern

  # Use in place of pagy(collection, ...options) or query.results(...options).
  def pagy_wrapper(collection_or_query, **options)
    param_keys = %i[limit page].select { |key| options[key].nil? }
    validate_pagy_params(param_keys) if param_keys.any? && respond_to?(:params)

    options[:limit] ||= pagy_param_default(:limit, Pagy::OPTIONS[:limit])
    options[:page] ||= pagy_param_default(:page, 1)

    return collection_or_query.results(**options) if collection_or_query.respond_to?(:results)

    pagy(collection_or_query, **options)
  end

  private

  def pagy_param_default(key, default)
    return default unless respond_to?(:params)

    params[key] || default
  end

  # Raises Pagy::RangeError when :page is among the offending keys (handled by
  # resetting to the first page), otherwise Pagy::OptionError (:limit only).
  def validate_pagy_params(keys)
    offending_keys = keys.select { |key| invalid_pagy_integer?(params[key]) }
    return if offending_keys.empty?

    error_class = offending_keys.include?(:page) ? Pagy::RangeError : Pagy::OptionError
    raise error_class.new(
      Pagy::OPTIONS, offending_keys, 'to be a full integer', params.values_at(*offending_keys)
    )
  end

  def invalid_pagy_integer?(value)
    return false if value.blank?

    Integer(value.to_s, 10)
    false
  rescue ArgumentError, TypeError
    true
  end

  # Redirects to the current URL with only the offending param(s) reset to defaults.
  def redirect_to_sanitized_pagy_params(exception)
    defaults = { limit: Pagy::OPTIONS[:limit], page: 1 }
    overrides = Array(exception.option).index_with { |key| defaults[key] }
    redirect_to url_for(params.to_unsafe_h.merge(overrides))
  end

  # Rescues Pagy::RangeError (valid but out-of-range :page) by redirecting to the
  # first page, preserving the existing params and only keeping :limit if it was
  # already present.
  def redirect_to_first_page
    overrides = { page: 1 }

    if params[:limit].present?
      overrides[:limit] = params[:limit] = if invalid_pagy_integer?(params[:limit])
                                             Pagy::OPTIONS[:limit]
                                           else
                                             params[:limit]
                                           end
    end

    redirect_to url_for(params.to_unsafe_h.merge(overrides))
  end
end
