# frozen_string_literal: true

# entity class for Project
class Project < ApplicationRecord
  acts_as_paranoid

  broadcasts_refreshes

  before_restore :restore_namespace
  after_destroy :destroy_namespace
  after_commit :propagate_samples_count_change, if: :saved_change_to_samples_count?

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

  def self.icon
    :stack
  end

  def broadcast_refresh_later_to_samples_table
    broadcast_refresh_later_to self, :samples if self && !deleted?

    # Broadcast to all ancestor groups since they display samples from child projects/groups.
    # This ensures group sample views are notified of changes in nested projects.
    namespace.self_and_ancestors_of_type(Group.sti_name).each do |namespace|
      next if namespace&.deleted?

      broadcast_refresh_later_to namespace, :samples
    end
  end

  # Update the project's sample count by a given delta and propagate changes to ancestors.
  # @param delta [Integer] positive or negative change in sample count
  def update_samples_count_delta(delta)
    return if delta.zero?

    if delta.positive?
      Project.increment_counter(:samples_count, id, by: delta) # rubocop:disable Rails/SkipsModelValidations
    else
      Project.decrement_counter(:samples_count, id, by: delta.abs) # rubocop:disable Rails/SkipsModelValidations
    end

    # Propagate the delta to group ancestors directly
    namespace.propagate_samples_count_delta(delta)
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

  # Propagate sample count changes to group namespace ancestors.
  # Called when samples_count is updated (e.g., via counter_cache on Sample creation/deletion).
  def propagate_samples_count_change
    old_count, new_count = saved_change_to_samples_count
    delta = new_count - old_count
    namespace.propagate_samples_count_delta(delta)
  end
end
