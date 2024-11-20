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
    column = column.gsub('metadata_', 'metadata.') if column.match?(/metadata_/)
    assign_attributes(column:, direction:)
  end

  def ransack_results
    return Sample.none unless valid?

    sort_samples.ransack(ransack_params).result
  end

  def searchkick_pagy_results
    return Sample.pagy_search('') unless valid?

    Sample.pagy_search(name_or_puid_cont.presence || '*', **searchkick_kwargs)
  end

  def searchkick_results
    return Sample.search('') unless valid?

    Sample.search(name_or_puid_cont.presence || '*', **searchkick_kwargs)
  end

  private

  def searchkick_kwargs
    { fields: [{ name: :text_middle }, { puid: :text_middle }],
      misspellings: false,
      where: { project_id: project_ids }.merge((
       if name_or_puid_in.present?
         { _or: [{ name: name_or_puid_in },
                 { puid: name_or_puid_in }] }
       else
         {}
       end
     )),
      order: { "#{column}": direction },
      includes: [project: { namespace: [{ parent: :route }, :route] }] }
  end

  def ransack_params
    {
      name_or_puid_cont: name_or_puid_cont,
      name_or_puid_in: name_or_puid_in
    }.compact
  end

  def sort_samples(scope = Sample.where(project_id: project_ids))
    if column.starts_with? 'metadata.'
      field = column.gsub('metadata.', '')
      scope.order(Sample.metadata_sort(field, direction))
    else
      scope.order("#{column} #{direction}")
    end
  end
end
