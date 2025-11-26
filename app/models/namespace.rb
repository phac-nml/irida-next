# frozen_string_literal: true

# Namespace base class
class Namespace < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include TrackActivity

  has_logidze
  acts_as_paranoid

  include HasPuid
  include Routable

  MAX_ANCESTORS = 10

  belongs_to :owner, class_name: 'User', optional: true

  belongs_to :parent, class_name: 'Namespace', optional: true

  has_many :children,
           lambda {
             where(type: Group.sti_name)
           },
           class_name: 'Namespace', foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  has_many :attachments, as: :attachable, dependent: :destroy

  validates :owner, presence: true, if: ->(n) { n.owner_required? }
  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { case_sensitive: false, scope: %i[type] }, if: -> { parent_id.blank? }
  validates :name, uniqueness: { case_sensitive: false, scope: %i[type parent_id] }, if: -> { parent_id.present? }

  validates :description, length: { maximum: 255 }

  validates :path, presence: true, length: { minimum: 3, maximum: 255 }

  validates :path, namespace_path: true

  validate :validate_type
  validate :validate_parent_type
  validate :validate_nesting_level

  scope :include_route, -> { includes(:route) }

  after_restore :restore_routes

  class << self
    def sti_class_for(type_name)
      case type_name
      when Group.sti_name
        Group
      when Namespaces::ProjectNamespace.sti_name
        Namespaces::ProjectNamespace
      when Namespaces::UserNamespace.sti_name
        Namespaces::UserNamespace
      else
        Namespace
      end
    end

    def by_path(path)
      find_by('lower(path) = :value', value: path.downcase)
    end

    def as_ids
      select(Arel.sql('namespaces.id'))
    end

    def self_and_ancestors
      # build sql expression to select the route ids of the self and ancestral groups
      route_id_select =
        joins(:route)
        .joins('LEFT JOIN routes ancestral_routes on ancestral_routes.id = routes.id ' \
               "or concat(routes.path,'/') like concat(ancestral_routes.path,'/%')")
        .select(Arel.sql('distinct routes.id')).to_sql

      unscoped
        .joins(:route)
        .where(Arel.sql(format('routes.id in (%s)', route_id_select)))
    end

    def self_and_descendants
      # build sql expression to select the route ids of the self and descendant groups
      route_id_select =
        joins(:route)
        .joins('LEFT JOIN routes descendant_routes on descendant_routes.id = routes.id ' \
               "or descendant_routes.path like concat(routes.path,'/%')")
        .select(Arel.sql('distinct descendant_routes.id')).to_sql

      unscoped
        .joins(:route)
        .where(Arel.sql(format('routes.id in (%s)', route_id_select)))
    end

    def self_and_descendant_ids
      self_and_descendants.as_ids
    end

    def without_descendants
      wildcard_path_select =
        joins(:route)
        .select(Arel.sql("concat(routes.path,'/%')")).to_sql

      joins(:route)
        .where(Arel.sql(format('routes.path not ILIKE all(array(%s))', wildcard_path_select)))
    end

    def ransackable_attributes(_auth_object = nil)
      %w[created_at deleted_at name puid updated_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[]
    end

    def subtract_from_metadata_summary_count(namespaces, metadata_summary, by_one)
      return if metadata_summary.empty?

      update_metadata_summary_counts(namespaces, metadata_summary, by_one: by_one, addition: false)
    end

    def add_to_metadata_summary_count(namespaces, metadata_summary, by_one)
      return if metadata_summary.empty?

      update_metadata_summary_counts(namespaces, metadata_summary, by_one: by_one, addition: true)
    end

    private

    def update_metadata_summary_counts(namespaces, metadata_summary, by_one: false, addition: true)
      metadata_summary_update_sql = build_metadata_summary_update_sql(metadata_summary,
                                                                      addition ? Arel::Nodes::Addition : Arel::Nodes::Subtraction,
                                                                      by_one:)

      jsonb_each_function = Arel::Nodes::NamedFunction.new(
        'jsonb_each',
        [Namespace.arel_table[:metadata_summary].concat(metadata_summary_update_sql)]
      )

      sm = Arel::SelectManager.new(jsonb_each_function.as('entry'))
      sm.project(
        Arel::Nodes::SqlLiteral.new("coalesce(jsonb_object_agg(entry.key, entry.value), '{}'::jsonb) as filtered_jsonb")
      ).where(Arel::Nodes::SqlLiteral.new('entry.value::integer > 0'))

      Namespace.transaction do
        locked_namespaces = Namespace.where(id: namespaces.pluck(:id)).lock
        locked_namespaces.update_all(metadata_summary: Arel::Nodes::Grouping.new(sm)) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def build_metadata_summary_update_sql(metadata_summary, operation = Arel::Nodes::Addition, by_one: false)
      new_metadata_summary = nil
      metadata_summary.each do |metadata_field, count|
        field_metadata_summary = single_field_metadata_summary_jsonb(metadata_field, by_one ? 1 : count, operation)

        new_metadata_summary = if new_metadata_summary.nil?
                                 field_metadata_summary
                               else
                                 Arel::Nodes::InfixOperation.new('||', new_metadata_summary, field_metadata_summary)
                               end
      end

      new_metadata_summary
    end

    def single_field_metadata_summary_jsonb(metadata_field, count, operation) # rubocop:disable Metrics/MethodLength
      Arel::Nodes::InfixOperation.new(
        '::',
        Arel::Nodes::NamedFunction.new(
          'concat', [
            Arel::Nodes::Quoted.new('{'),
            Arel::Nodes::Quoted.new("\"#{metadata_field}\": "),
            operation.new(
              Arel::Nodes::NamedFunction.new(
                'coalesce',
                [
                  Arel::Nodes::InfixOperation.new(
                    '::',
                    Arel::Nodes::Grouping.new(
                      Arel::Nodes::InfixOperation.new(
                        '->>', Namespace.arel_table[:metadata_summary], Arel::Nodes::Quoted.new(metadata_field)
                      )
                    ),
                    Arel::Nodes::SqlLiteral.new('integer')
                  ),
                  Arel::Nodes::SqlLiteral.new('0')
                ]
              ),
              count
            ),
            Arel::Nodes::Quoted.new('}')
          ]
        ), Arel::Nodes::SqlLiteral.new('jsonb')
      )
    end
  end

  def ancestors
    return self.class.none if parent_id.blank?

    self_and_ancestors.where.not(id:)
  end

  def ancestor_ids
    ancestors.as_ids
  end

  def self_and_ancestors
    return self.class.where(id:) if parent_id.blank?

    self.class
        .joins(:route)
        .where(
          Arel.sql(
            format(
              "(select concat(path,'/') from routes where source_id = '%s') like concat(routes.path, '/%%')", id
            )
          )
        )
  end

  def self_and_ancestors_of_type(types)
    Namespace.joins(:route).where(Arel.sql(format(
                                             "(select concat(path,'/') from routes where source_id = '%s') like concat(routes.path, '/%%')", id
                                           )))
             .where(type: types)
  end

  def self_and_ancestor_ids
    self_and_ancestors.as_ids
  end

  def descendants
    self_and_descendants.where.not(id:)
  end

  def self_and_descendants
    route_path = Route.arel_table[:path]

    self.class.joins(:route).where(route_path.matches_any([full_path, "#{full_path}/%"]))
  end

  def self_and_descendants_of_type(types)
    route_path = Route.arel_table[:path]

    Namespace.joins(:route).where(route_path.matches_any([full_path, "#{full_path}/%"]))
             .where(type: types)
  end

  def self_and_descendant_ids
    self_and_descendants.as_ids
  end

  def to_param
    full_path
  end

  def human_name
    full_name
  end

  def group_namespace?
    type == Group.sti_name
  end

  def project_namespace?
    type == Namespaces::ProjectNamespace.sti_name
  end

  def user_namespace?
    type == Namespaces::UserNamespace.sti_name
  end

  def owner_required?
    user_namespace? || project_namespace?
  end

  def has_parent? # rubocop:disable Naming/PredicatePrefix
    parent_id.present? || parent.present?
  end

  def children_allowed?
    return false if project_namespace?

    ancestors.count >= Namespace::MAX_ANCESTORS - 2
  end

  def children_of_type?(type)
    Namespace.exists?(parent: self, type:)
  end

  def children_of_type(type)
    Namespace.where(parent: self, type:)
  end

  def validate_type
    return unless type.nil?

    errors.add(:type, 'Namespace is not allowed to be directly created')
  end

  def validate_parent_type # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    unless has_parent?
      errors.add(:parent_id, 'must be set for a project namespace') if project_namespace?

      return
    end

    errors.add(:parent_id, 'project namespace cannot be the parent of another namespace') if parent&.project_namespace?

    if user_namespace?
      errors.add(:parent_id, 'cannot be used for user namespace')
    elsif group_namespace?
      errors.add(:parent_id, 'user namespace cannot be the parent of another namespace') if parent.user_namespace?
    end
  end

  def validate_nesting_level
    return unless has_parent? && (parent.ancestors.count + 1) > MAX_ANCESTORS - 1

    errors.add(:parent_id, 'nesting level too deep')
  end

  # self = namespace receiving transferred_namespace
  # old_namespace = the old namespace transferred_namespace originated from
  def update_metadata_summary_by_namespace_transfer(transferred_namespace, old_namespace)
    metadata_to_update = transferred_namespace.metadata_summary
    return if metadata_to_update.empty?

    unless old_namespace.nil? || old_namespace.type == Namespaces::UserNamespace.sti_name
      Namespace.subtract_from_metadata_summary_count(old_namespace.self_and_ancestors, metadata_to_update, false)
    end

    return unless type != Namespaces::UserNamespace.sti_name

    Namespace.add_to_metadata_summary_count(self_and_ancestors, metadata_to_update, false)
  end

  def update_metadata_summary_by_namespace_deletion
    return if metadata_summary.empty?

    Namespace.subtract_from_metadata_summary_count(parent.self_and_ancestors, metadata_summary, false)
  end

  def self.model_prefix
    raise NotImplementedError, 'The underlying class should implement this method to set the model prefix.'
  end

  def metadata_fields
    metadata_summary.keys.sort
  end

  def metadata_templates
    MetadataTemplate.where(namespace: self)
  end

  private

  # Method to restore namespace routes when the namespace is restored
  def restore_routes
    Route.restore(Route.only_deleted.find_by(source_id: id)&.id, recursive: true)
  end
end
