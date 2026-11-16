# frozen_string_literal: true

# Configuration for searchable attachment fields and their enum values.
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

  # Fields that only accept numeric operators/values.
  NUMERIC_FIELDS = %w[byte_size].freeze

  def fields
    SEARCHABLE_FIELDS.dup
  end

  def numeric_fields
    NUMERIC_FIELDS.dup
  end

  # Enum field configurations for select dropdowns, keyed by field name.
  def enum_fields
    {
      'metadata.type' => { values: %w[assembly pe illumina_pe] },
      'metadata.format' => { values: Attachment::FORMAT_REGEX.keys },
      'metadata.compression' => { values: %w[none gzip] }
    }
  end
end
