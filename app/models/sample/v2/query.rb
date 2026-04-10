# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/OneClassPerFile

# Namespace module for V2 query objects scoped to Sample.
module Sample::V2
end

# Plain Ruby Object (PORO) composing Executor + TreeValidator + Pagy pagination.
# Translates a GroupNode/ConditionNode tree into a filtered, sorted, paginated
# ActiveRecord::Relation. Returns [Pagy, ActiveRecord::Relation] tuple.
class Sample::V2::Query
  include Pagy::Method

  attr_reader :tree, :errors

  def initialize(tree:, scope:, sort: 'updated_at desc', page: 1, limit: 20)
    @tree = tree
    @scope = scope
    @sort = sort
    @page = page.to_i
    @limit = limit.to_i
    @errors = []
  end

  def valid?
    result = AdvancedSearch::V2::TreeValidator.new.validate(@tree)
    @errors = result[:errors]
    result[:valid]
  end

  def relation
    raise ArgumentError, 'Cannot execute invalid query tree' unless valid?

    apply_sort(AdvancedSearch::V2::Executor.new(@tree, @scope).call)
  end

  def results
    pagy(relation, limit: @limit, page: @page, raise_range_error: true)
  end

  private

  # Pagy::Method requires a #request method returning a request-like object.
  # Provide a minimal hash — pagination params are injected via #results arguments.
  def request
    { params: {} }
  end

  def apply_sort(relation)
    column, direction = @sort.to_s.split(' ', 2)
    direction = 'desc' unless %w[asc desc].include?(direction)

    if column&.start_with?('metadata_')
      metadata_key = column.delete_prefix('metadata_')
      relation.order(Sample.metadata_sort(metadata_key, direction))
    elsif Sample.column_names.include?(column)
      ordered = relation.order(column => direction)
      column == 'id' ? ordered : ordered.order(id: direction)
    else
      relation.order(updated_at: :desc)
    end
  end
end

# rubocop:enable Style/ClassAndModuleChildren, Style/OneClassPerFile
