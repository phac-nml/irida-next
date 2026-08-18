# frozen_string_literal: true

# Stable entrypoint for rendering Nextflow component across UI versions.
class NextflowComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v2: Nextflow::V2::Component
  }.freeze

  DEFAULT_VERSION = :v2

  VERSION_RESOLVER = -> { :v2 }
end
