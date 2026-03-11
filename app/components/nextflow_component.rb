# frozen_string_literal: true

# Stable entrypoint for rendering Nextflow component across UI versions.
class NextflowComponent < Versioning::VersionedComponent
  IMPLEMENTATIONS = {
    v1: Nextflow::V1::Component,
    v2: Nextflow::V2::Component
  }.freeze

  VERSION_RESOLVER = lambda {
    Flipper.enabled?(:v2_samplesheet, Current.user) ? :v2 : :v1
  }
end
