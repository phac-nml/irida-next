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

  validate :validate_type, if: -> { new_record? || type_changed? }
  validate :validate_parent_type, if: -> { new_record? || parent_id_changed? }
  validate :validate_nesting_level, if: -> { new_record? || parent_id_changed? }

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
      find_by(arel_table[:path].lower.eq(path.downcase))
    end

    def as_ids
      select(Namespace.arel_table[:id])
    end

    def self_and_ancestors # rubocop:disable Metrics/AbcSize
      # build sql expression to select the route ids of the self and ancestral groups
      ancestral_routes = Arel::Table.new(Route.table_name, as: 'ancestral_routes')
      ancestral_route_ids = Route.arel_table.join(ancestral_routes, Arel::Nodes::OuterJoin).on(
        ancestral_routes[:id].eq(Route.arel_table[:id]).or(
          Arel::Nodes::NamedFunction.new('CONCAT', [Route.arel_table[:path], Arel::Nodes::Quoted.new('/')]).matches(
            Arel::Nodes::NamedFunction.new('CONCAT', [ancestral_routes[:path], Arel::Nodes::Quoted.new('/%')])
          )
        )
      ).where(
        Route.arel_table[:source_type].eq(Namespace.sti_name).and(
          Route.arel_table[:source_id].in(select(:id).arel)
        ).and(Route.arel_table[:deleted_at].eq(nil))
      ).project(Route.arel_table[:id]).distinct

      unscoped
        .joins(:route)
        .where(Route.arel_table[:id].in(ancestral_route_ids))
    end

    def self_and_descendants # rubocop:disable Metrics/AbcSize
      # build sql expression to select the route ids of the self and descendant groups
      descendant_routes = Arel::Table.new(Route.table_name, as: 'descendant_routes')
      descendant_route_ids = Route.arel_table.join(descendant_routes, Arel::Nodes::OuterJoin).on(
        descendant_routes[:id].eq(Route.arel_table[:id]).or(
          descendant_routes[:path].matches(
            Arel::Nodes::NamedFunction.new('CONCAT', [Route.arel_table[:path], Arel::Nodes::Quoted.new('/%')])
          )
        )
      ).where(
        Route.arel_table[:source_type].eq(Namespace.sti_name).and(
          Route.arel_table[:source_id].in(select(:id).arel)
        ).and(Route.arel_table[:deleted_at].eq(nil))
      ).project(descendant_routes[:id]).distinct

      unscoped
        .joins(:route)
        .where(Route.arel_table[:id].in(descendant_route_ids))
    end

    def self_and_descendant_ids
      self_and_descendants.as_ids
    end

    def without_descendants
      wildcard_path_select =
        joins(:route)
        .select(Arel::Nodes::NamedFunction.new('CONCAT', [Route.arel_table[:path], Arel::Nodes::Quoted.new('/%')])).arel

      joins(:route)
        .where(Route.arel_table[:path].does_not_match(
                 Arel::Nodes::NamedFunction.new('ALL',
                                                [Arel::Nodes::NamedFunction.new(
                                                  'ARRAY', [wildcard_path_select]
                                                )])
               ))
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

    def update_metadata_summary_counts(namespaces, metadata_summary, by_one: false, addition: true) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      metadata_summary_update_sql = build_metadata_summary_update_sql(metadata_summary,
                                                                      addition ? Arel::Nodes::Addition : Arel::Nodes::Subtraction,
                                                                      by_one:)

      entry_table = Arel::Table.new(
        Arel::Nodes::NamedFunction.new(
          'jsonb_each',
          [Namespace.arel_table[:metadata_summary].concat(metadata_summary_update_sql)]
        ),
        as: 'entry'
      )

      updated_metadata_summary = entry_table.project(
        Arel::Nodes::NamedFunction.new(
          'coalesce',
          [
            Arel::Nodes::NamedFunction.new('jsonb_object_agg', [entry_table[:key], entry_table[:value]]),
            Arel::Nodes::InfixOperation.new('::', Arel::Nodes::Quoted.new('{}'), Arel::Nodes::SqlLiteral.new('jsonb'))
          ]
        )
      ).where(Arel::Nodes::InfixOperation.new('::', entry_table[:value], Arel::Nodes::SqlLiteral.new('integer')).gt(0))

      Namespace.transaction do
        locked_namespaces = namespaces.lock('FOR UPDATE')
        locked_namespaces.update_all(metadata_summary: Arel::Nodes::Grouping.new(updated_metadata_summary)) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def build_metadata_summary_update_sql(metadata_summary, operation = Arel::Nodes::Addition, by_one: false)
      metadata_summary_update_sql = metadata_summary.map do |metadata_field, count|
        single_field_metadata_summary_jsonb(metadata_field, by_one ? 1 : count, operation)
      end

      Arel::Nodes::Grouping.new(Arel.sql(metadata_summary_update_sql.map(&:to_sql).join(' || ')))
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

    self_and_ancestors_of_type(self.class.sti_name)
  end

  def self_and_ancestors_of_type(types)
    Namespace.joins(:route)
             .where(
               Arel::Nodes::Grouping.new(
                 Route.arel_table.project(
                   Arel::Nodes::NamedFunction.new('CONCAT',
                                                  [Route.arel_table[:path],
                                                   Arel::Nodes::Quoted.new('/')])
                 ).where(Route.arel_table[:source_id].eq(id))
               ).matches(Arel::Nodes::NamedFunction.new('CONCAT', [Route.arel_table[:path], Arel::Nodes::Quoted.new('/%%')]))
             ).where(type: types)
  end

  def self_and_ancestor_ids
    self_and_ancestors.as_ids
  end

  def descendants
    self_and_descendants.where.not(id:)
  end

  def self_and_descendants
    self_and_descendants_of_type(self.class.sti_name)
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
