# frozen_string_literal: true

class Attachment::FieldConfiguration # rubocop:disable Style/ClassAndModuleChildren
  ENUM_METADATA_FIELDS = %w[metadata.type metadata.format metadata.compression].freeze

  # List of searchable fields for attachments.
  SEARCHABLE_FIELDS = %w[
    id
    filename
    byte_size
    created_at
    metadata.type
    metadata.format
    metadata.compression
  ].freeze
end
