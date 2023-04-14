# frozen_string_literal: true

# Namespace base class
class Namespace < ApplicationRecord
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
  end

  def ancestor_ids
    ancestral_path_parts = route.split_path_parts[0...-1]

    route_path = Route.arel_table[:path]

    Namespace.joins(:route).where(route_path.in(ancestral_path_parts)).pluck(:id)
  end

  def ancestors
    Namespace.where(id: ancestor_ids)
  end

  def self_and_ancestors
    Namespace.where(id: [id] + ancestor_ids)
  end

  def descendant_ids
    route_path = Route.arel_table[:path]

    Namespace.joins(:route).where(route_path.matches("#{full_path}/%")).pluck(:id)
  end

  def descendants
    Namespace.where(id: descendant_ids)
  end

  def self_and_descendants
    Namespace.find([id] + descendant_ids)
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
