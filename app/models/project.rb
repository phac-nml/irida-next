# frozen_string_literal: true

# entity class for Project
class Project < ApplicationRecord
  acts_as_paranoid

  include HasPuid

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

  scope :include_route, -> { includes(namespace: [{ parent: :route }, :route]) }

  def to_param
    path
  end

  def self.model_prefix
    'PRJ'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[namespace]
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
