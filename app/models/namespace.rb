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

  class << self
    def sti_class_for(type_name)
      case type_name
      when Group.sti_name
        Group
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

  def ancestors
    result = []
    ns = self
    while ns.parent.present?
      result.unshift(ns.parent)
      ns = ns.parent
    end
    result
  end

  def human_name
    full_name
  end

  def group_namespace?
    type == Group.sti_name
  end

  def user_namespace?
    type == Namespaces::UserNamespace.sti_name
  end

  def owner_required?
    user_namespace?
  end

  def validate_type
    return unless type.nil?

    errors.add(:type, 'Namespace is not allowed to be directly created')
  end

  def validate_parent_type
    errors.add(:parent_id, 'User Namespaces cannot have a parent') if user_namespace? && parent.present?

    return unless group_namespace?
    return unless parent.present? && !parent.group_namespace?

    errors.add(:parent_id, 'Groups can only be children of another Group')
  end

  def validate_nesting_level
    return unless ancestors.count > MAX_ANCESTORS - 1

    errors.add(:parent_id, 'nesting level too deep')
  end
end
