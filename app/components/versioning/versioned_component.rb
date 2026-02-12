# frozen_string_literal: true

module Versioning
  # Shared helper for components that dispatch to versioned implementations.
  module VersionedComponent
    private

    def resolve_version(version:, valid_versions:, default_version:, &default_resolver)
      VersionResolver.resolve(
        version: version,
        valid_versions: valid_versions,
        default_version: default_version,
        &default_resolver
      )
    end
  end
end
