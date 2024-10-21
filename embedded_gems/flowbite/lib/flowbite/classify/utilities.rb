# frozen_string_literal: true

module Flowbite
  class Classify
    class Utilities
      UTILITIES = YAML.safe_load(
        File.read(
          File.join(File.dirname(__FILE__), "utilities.yml")
        ),
        permitted_classes: [Symbol]
      ).freeze

      BREAKPOINTS = ["", "-sm", "-md", "-lg", "-xl"].freeze

      SUPPORTED_KEY_CACHE = Hash.new { |h, k| h[k] = !UTILITIES[k].nil? }
      BREAKPOINT_INDEX_CACHE = Hash.new { |h, k| h[k] = BREAKPOINTS.index(k) }

      class << self
        attr_accessor :validate_class_names
        alias validate_class_names? validate_class_names

        def classname(key, val, breakpoint = "")
          return nil unless val

          if(valid = validate(key, val, breakpoint))
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
          unless supported_key?(key)
            raise ArgumentError, "#{key} is not a valid Primer utility key" if validate_class_names?

            return ""
          end

          unless breakpoint.empty? || responsive?(key, val)
            raise ArgumentError, "#{key} does not support responsive values" if validate_class_names?

            return ""
          end

          unless supported_value?(key, val)
            raise ArgumentError, "#{val} is not a valid value for :#{key}. Use one of #{mappings(key)}" if validate_class_names?

            return nil if [true, false].include?(val)

            return "#{key.to_s.dasherize}-#{val.to_s.dasherize}"
          end

          nil
        end
      end
    end
  end
end