# frozen_string_literal: true

# model to represent sample search form
class Sample::Query # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :column, :string
  attribute :direction, :string
  attribute :name_or_puid_cont, :string
  attribute :name_or_puid_in, default: -> { [] }
  attribute :project_ids, default: -> { [] }
  attribute :sort, :string, default: 'updated_at desc'

  validates :direction, inclusion: { in: %w[asc desc] }
  validates :project_ids, length: { minimum: 1 }

  def initialize(...)
    super
    self.sort = sort
  end

  def sort=(value)
    super
    column, direction = sort.split
    assign_attributes(column:, direction:)
  end

  def results
    return Sample.none unless valid?

    sort_samples.ransack(ransack_params).result
  end

  private

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end

  def sort_samples(scope = Sample.where(project_id: project_ids))
    if column.starts_with? 'metadata_'
      field = column.gsub('metadata_', '')
      scope.order(Sample.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end
end
