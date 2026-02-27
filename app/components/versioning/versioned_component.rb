# frozen_string_literal: true

module Versioning
  # Shared helper for components that dispatch to versioned implementations.
  class VersionedComponent
    VERSION_RESOLVER = -> { raise NotImplementedError, "VERSION_RESOLVER must be defined in #{name}" }

    DEFAULT_VERSION = :v1

    def self.new(*, version: nil, **)
      implementation_class(version: version).new(*, **)
    end

    def self.implementation_class(version: nil)
      self::IMPLEMENTATIONS.fetch(resolve_version(version: version))
    end

    def self.resolve_version(version: nil)
      VersionResolver.resolve(
        version: version,
        valid_versions: self::IMPLEMENTATIONS.keys,
        default_version: self::DEFAULT_VERSION,
        &self::VERSION_RESOLVER
      )
    end
  end
end
