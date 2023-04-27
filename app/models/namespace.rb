# frozen_string_literal: true

# Namespace base class
class Namespace < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Routable

  MAX_ANCESTORS = 10

  belongs_to :owner, class_name: 'User', optional: true

  belongs_to :parent, class_name: 'Namespace', optional: true
  has_many :children, -> { where(type: Group.sti_name) }, class_name: 'Namespace', foreign_key: :parent_id # rubocop:disable Rails/InverseOf,Rails/HasManyOrHasOneDependent

  validates :owner, presence: true, if: ->(n) { n.owner_required? }
  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[type parent_id] }, if: -> { parent_id.present? }

  validates :description, length: { maximum: 255 }

  validates :path, presence: true, length: { minimum: 3, maximum: 255 }

  validates :path, namespace_path: true

  validate :validate_type
  validate :validate_parent_type
  validate :validate_nesting_level

  scope :include_route, -> { includes(:route) }

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

    def self_and_ancestors # rubocop:disable Metrics/AbcSize
      self_paths = joins(:route).pluck('routes.path')

      return none if self_paths.empty?

      ancestral_paths = []
      self_paths.each do |path|
        path.split('/').each_with_index do |_part, index|
          ancestral_paths << path.split('/')[0..index].join('/')
        end
      end

      paths = self_paths | ancestral_paths

      route_path = Route.arel_table[:path]

      unscoped
        .distinct
        .joins(:route)
        .where(route_path.in(paths))
    end

    def self_and_descendants
      self_paths = joins(:route).pluck('routes.path')

      return none if self_paths.empty?

      fuzzy_paths = self_paths.map { |path| "#{path}/%" }

      paths = self_paths | fuzzy_paths

      route_path = Route.arel_table[:path]

      unscoped
        .distinct
        .joins(:route)
        .where(route_path.matches_any(paths))
    end

    def self_and_descendant_ids
      self_and_descendants.as_ids
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

    ancestral_path_parts = route.split_path_parts

    route_path = Route.arel_table[:path]

    self.class.joins(:route).where(route_path.in(ancestral_path_parts))
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

  def has_parent? # rubocop:disable Naming/PredicateName
    parent_id.present? || parent.present?
  end

  def children_allowed?
    false if project_namespace?

    ancestors.count >= Namespace::MAX_ANCESTORS - 2
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
    return unless has_parent? && ancestors.count > MAX_ANCESTORS - 1

    errors.add(:parent_id, 'nesting level too deep')
  end
end
