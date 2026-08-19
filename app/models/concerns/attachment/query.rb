# frozen_string_literal: true

# Model to represent attachment search form
# Provides advanced search capabilities for filtering attachments
# Supports groups, conditions, operators, basic search, and pagination
class Attachment::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  class ResultTypeError < StandardError
  end

  allowed_sort_columns :id, :created_at

  self.enum_metadata_fields = Attachment::FieldConfiguration::ENUM_METADATA_FIELDS

  attribute :puid_or_file_blob_filename_cont, :string
  attribute :groups, default: -> { [] }

  query_for Attachment

  def search_group_class
    Attachment::SearchGroup
  end

  private

  def add_condition(scope, condition)
    field_name = normalize_condition_field(condition)

    if %w[filename byte_size].include?(field_name)
      scope = scope.joins(:file_blob)
      node = ActiveStorage::Blob.arel_table[field_name]
      value = normalize_condition_value(condition)
      handler = AdvancedSearch::Filtering::OPERATOR_HANDLERS[condition.operator]
      return scope unless handler

      return send(handler, scope, node, value, field_name)
    end

    super
  end

  def normalize_condition_field(condition)
    return 'puid' if condition.field == 'id'

    condition.field
  end

  def ransack_params
    {
      puid_or_file_blob_filename_cont: puid_or_file_blob_filename_cont
    }.compact
  end
end
