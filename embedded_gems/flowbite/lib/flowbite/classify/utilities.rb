# frozen_string_literal: true

module Flowbite
  class Classify
    # :nodoc:
    class Utilities
      UTILITIES = YAML.safe_load_file(File.join(__dir__, 'utilities.yml'), permitted_classes: [Symbol]).freeze

      BREAKPOINTS = ['', '-sm', '-md', '-lg', '-xl'].freeze

      SUPPORTED_KEY_CACHE = Hash.new { |h, k| h[k] = !UTILITIES[k].nil? }
      BREAKPOINT_INDEX_CACHE = Hash.new { |h, k| h[k] = BREAKPOINTS.index(k) }

      class << self
        attr_accessor :validate_class_names
        alias validate_class_names? validate_class_names

        def classname(key, val, breakpoint = '')
          return nil unless val

          if (valid = validate(key, val, breakpoint))
            valid
          else
            UTILITIES[key][val][BREAKPOINTS.index(breakpoint)]
          end
        end

        # Does the Utility class support the given key
        #
        # returns Boolean
        def supported_key?(key)
          SUPPORTED_KEY_CACHE[key]
        end

        # Does the Utility class support the given key and value
        #
        # returns Boolean
        def supported_value?(key, val)
          supported_key?(key) && !UTILITIES[key][val].nil?
        end

        def validate(key, val, breakpoint)
          return handle_invalid_key(key) unless supported_key?(key)
          return handle_invalid_breakpoint(key, val, breakpoint) unless valid_breakpoint?(key, val, breakpoint)
          return handle_invalid_value(key, val) unless supported_value?(key, val)

          nil
        end

        private

        def handle_invalid_key(key)
          raise ArgumentError, "#{key} is not a valid Primer utility key" if validate_class_names?

          ''
        end

        def handle_invalid_breakpoint(key, _val, _breakpoint)
          raise ArgumentError, "#{key} does not support responsive values" if validate_class_names?

          ''
        end

        def handle_invalid_value(key, val)
          if validate_class_names?
            raise ArgumentError, "#{val} is not a valid value for :#{key}. Use one of #{mappings(key)}"
          end
          return nil if [true, false].include?(val)

          "#{key.to_s.dasherize}-#{val.to_s.dasherize}"
        end

        def valid_breakpoint?(key, val, breakpoint)
          breakpoint.empty? || responsive?(key, val)
        end
      end
    end
  end
end
