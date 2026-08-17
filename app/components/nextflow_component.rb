# frozen_string_literal: true

# Stable entrypoint for rendering Nextflow component across UI versions.
class NextflowComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Nextflow::V2::Component
  }.freeze
  VERSION_RESOLVER = -> { :v1 }
end
