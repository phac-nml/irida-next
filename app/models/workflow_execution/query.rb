# frozen_string_literal: true

# Model to represent workflow execution search form
# Provides advanced search capabilities for filtering workflow executions
# Supports groups, conditions, operators, basic search, and pagination
class WorkflowExecution::Query # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Pagy::Backend
  include AdvancedSearchable
  include AdvancedSearchConditions
  include AdvancedSearchConditionDispatcher
  prepend SortableQuery
  include AdvancedSearchQuery

  ResultTypeError = Class.new(StandardError)

  ALLOWED_SORT_COLUMNS = %w[id name run_id state created_at updated_at].freeze

  attribute :column, :string
  attribute :direction, :string
  attribute :name_or_id_cont, :string
  attribute :name_or_id_in, default: -> { [] }
  attribute :namespace_ids, default: -> { [] }
  attribute :groups, default: lambda {
    [WorkflowExecution::SearchGroup.new(
      conditions: [WorkflowExecution::SearchCondition.new(field: '', operator: '', value: '')]
    )]
  }
  attribute :sort, :string, default: 'updated_at desc'
  attribute :advanced_query, :boolean, default: false

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :namespace_ids, length: { minimum: 1 }
  validates :column, inclusion: {
    in: lambda { |record|
      ALLOWED_SORT_COLUMNS + [record.column].select { |c| c&.start_with?('metadata.') }
    }
  }
  validates_with WorkflowExecutionAdvancedSearchGroupValidator

  def initialize(attributes = {}, scope: WorkflowExecution, **kwargs)
    attributes = if attributes.present?
                   attributes.merge(kwargs)
                 else
                   kwargs
                 end

    super(attributes)
    @scope = scope
    self.sort = sort
    self.advanced_query = advanced_query?
    self.groups = groups
  end

  private

  def model_class
    WorkflowExecution
  end

  def search_scope
    @scope
  end

  def filter_column
    :namespace_id
  end

  def filter_ids
    namespace_ids
  end

  def normalize_condition_value(condition)
    return condition.value unless condition.field == 'state'

    if %w[in not_in].include?(condition.operator)
      condition.value.map { |v| WorkflowExecution.states[v] || v }
    else
      WorkflowExecution.states[condition.value] || condition.value
    end
  end

  def ransack_params
    {
      name_or_id_cont: name_or_id_cont,
      name_or_id_in: name_or_id_in
    }.compact
  end
end
