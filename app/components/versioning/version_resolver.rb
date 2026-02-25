# frozen_string_literal: true

module Versioning
  # Generic resolver for versioned component selection.
  class VersionResolver
    class << self
      # Resolves a version from explicit override or a default resolver.
      #
      # @param version [String, Symbol, nil] explicit version override
      # @param valid_versions [Enumerable<String,Symbol>] allowed versions
      # @param default_version [String, Symbol] fallback version
      # @yieldreturn [String, Symbol, nil] optional computed default version
      # @return [Symbol] normalized and validated version
      def resolve(version:, valid_versions:, default_version:, &default_resolver)
        valid = normalize_versions(valid_versions)
        fallback = normalize(default_version)

        unless valid.include?(fallback)
          raise ArgumentError, "Default version #{default_version.inspect} is not in valid_versions"
        end

        return validate!(normalize(version), valid) unless version.nil?

        resolved = default_resolver ? default_resolver.call : fallback
        validate!(normalize(resolved || fallback), valid)
      end

      private

      def normalize_versions(valid_versions)
        versions = Array(valid_versions).map { |candidate| normalize(candidate) }.uniq
        raise ArgumentError, 'valid_versions must not be empty' if versions.empty?

        versions
      end

      def normalize(value)
        value.to_s.downcase.to_sym
      end

      def validate!(version, valid)
        return version if valid.include?(version)

        raise ArgumentError, "Unknown version #{version.inspect}; expected one of: #{valid.join(', ')}"
      end
    end
  end
end
