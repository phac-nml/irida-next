# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  has_many :samples_workflow_executions, dependent: :nullify
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: %i[name project_id] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.metadata_sort(field, dir)
    metadata_field = Arel::Nodes::InfixOperation.new(
      '->',
      Sample.arel_table[:metadata],
      Arel::Nodes.build_quoted(field)
    )

    if dir.to_sym == :desc
      metadata_field.desc
    else
      metadata_field.asc
    end
  end
end
