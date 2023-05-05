# frozen_string_literal: true

# entity class for Project
class Project < ApplicationRecord
  has_many :samples, inverse_of: :project, dependent: :destroy

  belongs_to :creator, class_name: 'User'
  belongs_to :namespace, autosave: true, class_name: 'Namespaces::ProjectNamespace'
  accepts_nested_attributes_for :namespace

  delegate :description, to: :namespace
  delegate :name, to: :namespace
  delegate :path, to: :namespace
  delegate :human_name, to: :namespace
  delegate :full_path, to: :namespace

  scope :include_route, -> { includes(namespace: [{ parent: :route }, :route]) }

  def to_param
    path
  end
end
