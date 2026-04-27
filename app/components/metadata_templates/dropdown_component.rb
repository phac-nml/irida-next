# frozen_string_literal: true

module MetadataTemplates
  # Stable entrypoint for rendering a metadata templates drop down across UI versions.
  class DropdownComponent < Versioning::VersionedComponent
    IMPLEMENTATIONS = {
      v1: MetadataTemplates::Dropdown::V1::Component
    }.freeze

    VERSION_RESOLVER = -> { :v1 }
  end
end
