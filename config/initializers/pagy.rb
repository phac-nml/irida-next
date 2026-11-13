# frozen_string_literal: true

require 'pagy/toolbox/helpers/support/series'
require 'pagy/toolbox/helpers/support/a_lambda'
require 'pagy/classes/request'

# Pagy initializer file (43.2.1)
# See https://ddnexus.github.io/pagy/resources/initializer/

############ Global Options ################################################################
# See https://ddnexus.github.io/pagy/toolbox/options/ for details.
# Add your global options below. They will be applied globally.
# For example:
#
Pagy::OPTIONS[:limit] = 20 # Limit the items per page
Pagy::OPTIONS[:max_limit] = 100 # The client can request a limit up to 100
# Pagy::OPTIONS[:max_pages] = 200          # Allow only 200 pages
# Pagy::OPTIONS[:jsonapi] = true           # Use JSON:API compliant URLs

############ JavaScript ####################################################################
# See https://ddnexus.github.io/pagy/resources/javascript/ for details.
# Examples for Rails:
# For apps with an assets pipeline
# Rails.application.config.assets.paths << Pagy::ROOT.join('javascripts')
#
# For apps with a javascript builder (e.g. esbuild, webpack, etc.)
# javascript_dir = Rails.root.join('app/javascript')
# Pagy.sync_javascript(javascript_dir, 'pagy.mjs') if Rails.env.development?

############# Overriding Pagy::I18n Lookup #################################################
# Refer to https://ddnexus.github.io/pagy/resources/i18n/ for details.
# Override the I18n lookup by dropping your custom dictionary in some pagy dir.
# Example for Rails:
#
# Pagy::I18n.pathnames << Rails.root.join('config/locales/pagy')

############# I18n Gem Translation #########################################################
# See https://ddnexus.github.io/pagy/resources/i18n/ for details.
#
# Pagy.translate_with_the_slower_i18n_gem!

# Pagy::Calendar.localize_with_rails_i18n_gem(*your_locales)

# Custom exception for limit validation errors
class Pagy
  class LimitError < Pagy::OptionError # rubocop:disable Style/Documentation
    def initialize(limit_value)
      @limit_value = limit_value
      allowed = Viral::Pagy::LimitComponent::LIMITS.join(', ')
      super(Pagy, :limit, "one of: #{allowed}", limit_value)
    end
  end
end

# Validates only the :limit option, raising Pagy::LimitError when it isn't exactly one of the
# dropdown options (Viral::Pagy::LimitComponent::LIMITS), e.g. a clean integer like 30, or a
# dirty string like "50abc" that String#to_i would otherwise silently truncate to 50. All other
# options (e.g. :page, :count) pass through to Pagy's native assign_and_check via super.
module PagyAssignAndCheckOverride # rubocop:disable Style/OneClassPerFile
  def assign_and_check(name_min)
    validate_limit!(@options[:limit]) if name_min.key?(:limit) && @options[:limit].is_a?(String)

    super
  end

  private

  def validate_limit!(value)
    raise Pagy::LimitError, value unless value.respond_to?(:to_i)

    integer = value.to_i
    raise Pagy::LimitError, value if integer.to_s != value.to_s || Viral::Pagy::LimitComponent::LIMITS.exclude?(integer)
  end
end

# Overrides Pagy::Request#resolve_limit so that an invalid limit query param (e.g.
# "?limit=50abc") or one that isn't one of the dropdown options (Viral::Pagy::LimitComponent::LIMITS)
# raises Pagy::LimitError instead of being silently converted/accepted.
module PagyRequestResolveLimit # rubocop:disable Style/OneClassPerFile
  def resolve_limit
    default   = @options[:limit] || Pagy::DEFAULT[:limit]
    max_limit = @options[:max_limit]
    return default unless max_limit

    limit_key   = @options[:limit_key] || Pagy::DEFAULT[:limit_key]
    limit_value = @params.dig(@options[:root_key], limit_key) || @params[limit_key]

    validate_limit_value!(limit_value)

    limit = limit_value.to_s.to_i
    limit.zero? ? default : [limit, max_limit].min
  end

  private

  # Validate the string-to-integer conversion is clean and the value is an allowed dropdown option
  def validate_limit_value!(limit_value)
    return unless limit_value

    limit_str = limit_value.to_s
    limit_int = limit_str.to_i
    clean     = limit_int.to_s == limit_str
    allowed   = Viral::Pagy::LimitComponent::LIMITS.include?(limit_int)
    raise Pagy::LimitError, limit_value unless clean && allowed
  end
end

# Prepend at the end to override assign_and_check
Pagy.prepend PagyAssignAndCheckOverride
Pagy::Request.prepend PagyRequestResolveLimit
