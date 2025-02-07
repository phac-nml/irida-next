# frozen_string_literal: true

# entity class for Project
class Project < ApplicationRecord
  acts_as_paranoid

  broadcasts_refreshes

  before_restore :restore_namespace
  after_destroy :destroy_namespace

  belongs_to :creator, class_name: 'User'
  belongs_to :namespace, autosave: true, class_name: 'Namespaces::ProjectNamespace'

  has_many :samples, inverse_of: :project, dependent: :destroy

  accepts_nested_attributes_for :namespace

  delegate :description, to: :namespace
  delegate :name, to: :namespace
  delegate :path, to: :namespace
  delegate :human_name, to: :namespace
  delegate :full_path, to: :namespace
  delegate :abbreviated_path, to: :namespace
  delegate :full_name, to: :namespace
  delegate :parent, to: :namespace
  delegate :puid, to: :namespace
  delegate :metadata_summary, to: :namespace
  ransack_alias :name, :namespace_name
  ransack_alias :puid, :namespace_puid

  scope :include_route, -> { includes(namespace: [{ parent: :route }, :route]) }

  def to_param
    path
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id created_at updated_at] + _ransack_aliases.keys
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[namespace]
  end

  def accessible_from_namespace?(other_namespace) # rubocop:disable Metrics/AbcSize
    if other_namespace.project_namespace?
      namespace.id == other_namespace.id
    elsif other_namespace.group_namespace?
      return true if other_namespace.id == namespace.parent.id

      return true if namespace.self_and_ancestor_ids.where(id: other_namespace.id).count.positive?

      return true if namespace.shared_with_groups.where(id: other_namespace.id).count.positive?

      false
    else
      false
    end
  end

  private

  def destroy_namespace
    return if destroyed_by_association

    namespace.destroy
  end

  def restore_namespace
    namespace_to_restore = Namespace.only_deleted.find_by(id: namespace_id)
    return if namespace_to_restore.nil?

    Namespace.restore(namespace_to_restore.id, recursive: true)
  end
end
