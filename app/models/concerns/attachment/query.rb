# frozen_string_literal: true

# Model to represent attachment search form
# Provides advanced search capabilities for filtering attachments
# Supports groups, conditions, operators, basic search, and pagination
class Attachment::Query < AdvancedSearchQueryForm # rubocop:disable Style/ClassAndModuleChildren
  class ResultTypeError < StandardError
  end

  allowed_sort_columns :puid, :created_at, :updated_at, :file_blob_filename, :file_blob_byte_size

  self.enum_metadata_fields = Attachment::FieldConfiguration::ENUM_METADATA_FIELDS

  attribute :attachables, default: -> { [] }
  attribute :puid_or_file_blob_filename_cont, :string
  attribute :groups, default: -> { [] }

  query_for Attachment

  def search_group_class
    Attachment::SearchGroup
  end

  private

  def search_scope
    return scope if scope.present?
    return attachable_attachments_scope if attachables.any?

    super
  end

  def filtered_scope
    search_scope
  end

  def advanced_query_scope
    normalize_sort_scope(search_scope).merge(advanced_query_groups)
  end

  def apply_sort(scope)
    scope = normalize_sort_scope(scope)

    return scope unless column.present? && direction.present?

    case column
    when 'file_blob_filename', 'file_blob_byte_size'
      blob_column = column.delete_prefix('file_blob_')
      ordered_scope = scope.joins(:file_blob).order(ActiveStorage::Blob.arel_table[blob_column] => direction)
      ordered_scope.order(id: direction)
    else
      super
    end
  end

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

  def attachable_attachments_scope # rubocop:disable Metrics/AbcSize
    attachments = []
    attachables.each do |attachable|
      if attachables.size == 1 && attachable.instance_of?(WorkflowExecution)
        attachments << Attachment.where(attachable: attachable)
                                 .or(Attachment.where(attachable: attachable.samples_workflow_executions))
      elsif filter_requested?
        attachments.concat(attachable.attachments.all)
      else
        attachments.concat(
          attachable.attachments.where.not(Attachment.arel_table[:metadata].contains({ direction: 'reverse' }))
        )
      end
    end
    attachments
  end

  def normalize_condition_field(condition)
    return 'puid' if condition.field == 'id'

    condition.field
  end

  def default_sort
    'created_at desc'
  end

  def ransack_params
    {
      puid_or_file_blob_filename_cont: puid_or_file_blob_filename_cont
    }.compact
  end

  def filter_requested?
    puid_or_file_blob_filename_cont.present?
  end
end
