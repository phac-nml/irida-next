# -*- coding: utf-8 -*-

require 'w3c_validators'

# Module to deal with W3C Validator
#
# == Usage
#
# Put this file in one of your library-load paths in the test environment.
# Then, in /test/test_helper.rb
#
#   class ActiveSupport::TestCase
#     include TestW3cValidateHelper
#
# You may need to write in your +test_helper.rb+
#
#   require_relative './test_w3c_validate_helper'
#
# == Preparation
#
# Make sure your Gemfile contains:
#
#   group :test do
#     gem 'w3c_validators'
#   end
#
# To use these methods with your local VNU server (Default),
# you must install vnu first (+brew install vnu+ in macOS Homebrew).
#
# Then, start up a local VNU server in a separate terminal with (in the case of Homebrew):
#
#    java -Dnu.validator.servlet.bind-address=127.0.0.1 -cp $HOMEBREW_CELLAR/vnu/`vnu --version`/libexec/vnu.jar \
#      nu.validator.servlet.Main 8888
#
# NOTE1: If +$HOMEBREW_CELLAR+ is not defined, your machine is probably Intel and it is /usr/local/Cellar
# NOTE2: The vnu default server may be http://0.0.0.0:8888/ but vnu warns it will be changed to http://127.0.0.1:8888/
# NOTE3: If the server address is different from the default, you simply give is to the methods in thi module,
#   making sure you include the forward slash '/' at the tail.
module W3cValidationHelpers
  extend ActiveSupport::Concern

  # Default parameters for the methods in this module.
  #
  # @note For +validator_uri+, the trailing "/" is indispensable.
  DEF_W3C_VALIDATOR_PARAMS = {
    use_local: true,
    validator_uri: "http://#{ENV.fetch("VALIDATOR_HOST", "127.0.0.1")}:8888/",
  }.with_indifferent_access

  #module ClassMethods
  #end

  # Validates HTML with W3C (vnu) validator
  #
  # If environmental variable SKIP_W3C_VALIDATE is set and not '0' or 'false',
  # validation is skipped.
  #
  # The caller information is printed if fails.
  #
  # If the error message is insufficient, you may simply print out 'response.body',
  # before the calling statement in the caller, or better
  #
  #   @validator.validate_text(response.body).debug_messages.each do |key, value|
  #     puts "#{key}: #{value}"
  #   end
  #
  # (Note that +css_select('table').to_html+ in Controller tests etc may not work well
  # for HTML-debugging purposes because it would filter out invalid HTMLs like stray end tags.)
  #
  # @example to call this for the output of the index method of ArticlesController
  #    w3c_validate "Article index"  # defined in /test/test_w3c_validate_helper.rb (see for debugging help)
  #
  # @option name [String] Identifier for the error message.
  # @param use_local: #see setup_w3c_validator!
  # @param validator_uri: #see setup_w3c_validator!
  def w3c_validate(name="caller", use_local: nil, validator_uri: DEF_W3C_VALIDATOR_PARAMS[:validator_uri], content: response.body)
    return if ENV["RUBY_LSP_TEST_RUNNER"] && !ENV.key?("VALIDATOR_HOST")
    return if is_env_set_positive?('SKIP_W3C_VALIDATE')

    bind = caller_locations(1,1)[0]  # Ruby 2.0+
    caller_info = sprintf "%s:%d", bind.absolute_path.sub(%r@.*(/test/)@, '\1'), bind.lineno
    # NOTE: bind.label returns "block in <class:TranslationIntegrationTest>"

    ## W3C HTML validation (Costly operation)
    setup_w3c_validator!(use_local: use_local, validator_uri: validator_uri) if !instance_variable_defined?(:@validator)
    arerr = @validator.validate_text(content).errors
    arerr = _may_ignore_autocomplete_errors_for_hidden(arerr, "Ignores W3C validation errors for #{name} (#{caller_info}): ")
    arerr = _ignore_aria_errors_for_div_with_role_row(arerr, "Ignores W3C validation errors for #{name} (#{caller_info}): ")
    assert_empty arerr, "Failed for #{name} (#{caller_info}): W3C-HTML-validation-Errors(Size=#{arerr.size}): ("+arerr.map(&:to_s).join(") (")+")"
  end

  # Sets up the instance variable +@validator+ for preparation for running {#w3c_validate}
  #
  # Note that +validator_uri+ is ignored unless +use_local+ is true (Def: false).
  #
  # See [TestW3cValidateHelper::DEF_W3C_VALIDATOR_PARAMS] and also the comment for this module
  # for the default +validator_uri+
  #
  # If the optional argument +use_local+ is nil, the environmental variable +USE_W3C_SERVER_VALIDATOR+
  # is read; then, if it is not set or set "0" or "false", +use_local+ is set true,
  # and this method (attempts to) use the local VNU server.  Make sure your local VNU server is
  # up and running (the comment for this module for detail); otherwise,
  # +W3CValidators::ValidatorUnavailable+ exception is raised, perhaps many times.
  #
  # @param use_local: [Boolean, NilClass] If true (Def), use the local server. Otherwise, use the W3C server (use it sensibly!)
  # @param validator_uri: [String, NilClass] read only when use_local is true (Def).
  def setup_w3c_validator!(use_local: nil, validator_uri: DEF_W3C_VALIDATOR_PARAMS[:validator_uri])
    use_local = !is_env_set_positive?('USE_W3C_SERVER_VALIDATOR') if use_local.nil?

    hsin = {}
    hsin[:validator_uri] = validator_uri if use_local
    @validator = W3CValidators::NuValidator.new(**hsin)
  end


  # Botch fix of W3C validation errors for HTMLs generated by button_to
  #
  # On 2022-10-26, W3C validation implemented a check, which may raise an error:
  #
  # > An input element with a type attribute whose value is hidden must not have an autocomplete attribute whose value is on or off.
  #
  # This is particularly the case for HTMLs generated by button_to as of Rails 7.0.4.
  # It seems the implementation in Rails was deliberate to deal with mal-behaviours of
  # Firefox (Github Issue-42610: https://github.com/rails/rails/issues/42610 ).
  #
  # Whatever the reason is, it is highly inconvenient for developers who
  # use W3C validation for their Rails apps.
  #
  # This routine takes a W3C-validation error object (Array) and
  # return the same Array where the specific errors are deleted
  # so that one could still test the other potential errors with the W3C validation.
  # The said errors are recorded with +logger.warn+ (if +prefix+ is given).
  #
  # Note that this routine does nothing *unless* the config parameter
  #   config.ignore_w3c_validate_hidden_autocomplete = true
  # is set in config, e.g., in the file (if for testing use only):
  #   /config/environments/test.rb
  #
  # == References
  #
  # * Stackoverflow: https://stackoverflow.com/questions/74256523/rails-button-to-fails-with-w3c-validator
  # * Github: https://github.com/validator/validator/pull/1458
  # * HTML Spec: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#autofilling-form-controls:-the-autocomplete-attribute:autofill-anchor-mantle-2
  #
  # @example Usage, maybe in /test/test_helper.rb
  #   # Make sure to write in /config/environments/test.rb
  #   #    config.ignore_w3c_validate_hidden_autocomplete = true
  #   #
  #   bind = caller_locations(1,1)[0]  # Ruby 2.0+
  #   caller_info = sprintf "%s:%d", bind.absolute_path.sub(%r@.*(/test/)@, '\1'), bind.lineno
  #   errors = @validator.validate_text(response.body).errors
  #   prefix = "Ignores W3C validation errors (#{caller_info}): "
  #   errors = _may_ignore_autocomplete_errors_for_hidden(errors, prefix)
  #   assert_empty errors, "Failed in W3C validation: "+errors.map(&:to_s).inspect
  #
  # @param errs [Array<W3CValidators::Message>] Output of +@validator.validate_text(response.body).errors+
  # @param prefix [String] Prefix of the warning message recorded with Logger.
  #    If empty, no message is recorded in Logger.
  # @return [Array<String, W3CValidators::Message>]
  def _may_ignore_autocomplete_errors_for_hidden(errs, prefix="")
    removeds = []
    return errs if !Rails.configuration.ignore_w3c_validate_hidden_autocomplete
    errs.map{ |es|
      # Example of an Error:
      #   ERROR; line 165: An “input” element with a “type” attribute whose value is “hidden” must not have an “autocomplete” attribute whose value is “on” or “off”
      if /\AERROR\b.+\binput\b[^a-z]+\belement.+\btype\b.+\bhidden\b.+\bautocomplete\b[^a-z]+\battribute\b/i =~ es.to_s
        removeds << es
        nil
      else
        es
      end
    }.compact

  ensure
    # Records it in Logger
    if !removeds.empty? && !prefix.blank?
      Rails.logger.warn(prefix + removeds.map(&:to_s).uniq.inspect)
    end
  end

  # Botch fix of W3C validation errors for divs with role="row" inside role="treegrid"
  #
  # This routine takes a W3C-validation error object (Array) and
  # return the same Array where the specific errors are deleted
  # so that one could still test the other potential errors with the W3C validation.
  # The said errors are recorded with +logger.warn+ (if +prefix+ is given).
  #
  # == References
  #
  # * https://github.com/validator/validator/pull/1751
  # * https://www.w3.org/TR/wai-aria-1.2/#row
  #
  # @param errs [Array<W3CValidators::Message>] Output of +@validator.validate_text(response.body).errors+
  # @param prefix [String] Prefix of the warning message recorded with Logger.
  #    If empty, no message is recorded in Logger.
  # @return [Array<String, W3CValidators::Message>]
  def _ignore_aria_errors_for_div_with_role_row(errs, prefix="")
    removeds = []
    errs.map{ |es|
      # Example of an Error:
      #   ERROR; line 640: Attribute “aria-posinset” not allowed on element “div” at this point.
      #   ERROR; line 640: Attribute “aria-setsize” not allowed on element “div” at this point.
      if (/\AERROR\b.+\baria-(posinset|setsize)\b.*\bnot\b\s\ballowed\b\s\bon\b\s\belement\b.*\bdiv\b/i =~ es.to_s &&
        /treegrid-row/i =~ es.source
      )
        removeds << es
        nil
      else
        es
      end
    }.compact

  ensure
    # Records it in Logger
    if !removeds.empty? && !prefix.blank?
      Rails.logger.warn(prefix + removeds.map(&:to_s).uniq.inspect)
    end
  end

  ## Playing safe though this should be defined in /app/helpers/application_helper.rb
  if !method_defined?(:is_env_set_positive?)
    # true if the environmental variable is set and non-false
    def is_env_set_positive?(key)
      ENV.keys.include?(key.to_s) && !(%w(0 false FALSE f F)<<"").include?(ENV[key])
    end
  end

end
