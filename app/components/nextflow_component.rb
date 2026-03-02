# frozen_string_literal: true

# Stable entrypoint for rendering a drop down across UI versions.
class NextflowComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Nextflow::V1::Component,
    v2: Nextflow::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:deferred_samplesheet) ? :v2 : :v1
  }
end
