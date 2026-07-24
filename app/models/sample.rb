# frozen_string_literal: true

# entity class for Sample
class Sample < ApplicationRecord
  include MetadataSortable
  include HasPuid
  include History
  include FileSelector

  has_logidze
  acts_as_paranoid

  belongs_to :project, counter_cache: true

  after_destroy :propagate_samples_count_on_destroy
  after_restore :propagate_samples_count_on_restore
  after_commit :broadcast_refresh_later_to_samples_table
  after_commit :propagate_samples_count_on_create, on: :create
  after_commit :propagate_samples_count_on_transfer, on: :update

  has_many :attachments, as: :attachable, dependent: :destroy

  scope :sort_by_attachments_updated_at_nulls_last_asc,
        -> { order('attachments_updated_at ASC NULLS LAST') }

  scope :sort_by_attachments_updated_at_nulls_last_desc,
        -> { order('attachments_updated_at DESC NULLS LAST') }

  has_many :samples_workflow_executions, -> { with_deleted }, dependent: :nullify # rubocop:disable Rails/InverseOf
  has_many :workflow_executions, through: :samples_workflow_executions

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :name, uniqueness: { scope: :project_id }

  def self.model_prefix
    'SAM'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id puid name metadata created_at updated_at attachments_updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.icon
    :test_tube
  end

  def metadata_with_provenance
    sample_metadata = []
    metadata.each do |key, value|
      source_type = metadata_provenance[key]['source']
      source = if source_type == 'user'
                 User.find(metadata_provenance[key]['id']).email
               else
                 "#{I18n.t('models.sample.analysis')} #{metadata_provenance[key]['id']}"
               end
      sample_metadata << { key:, value:, source:, source_type:,
                           last_updated: metadata_provenance[key]['updated_at'] }
    end
    sample_metadata
  end

  def field?(field)
    metadata.key?(field)
  end

  def updatable_field?(field)
    return true unless metadata_provenance.key?(field)

    metadata_provenance[field]['source'] == 'user'
  end

  private

  # Propagate samples_count increment when sample is created.
  def propagate_samples_count_on_create
    project&.namespace&.propagate_samples_count_delta(1)
  end

  # Propagate samples_count increment when sample is restored.
  def propagate_samples_count_on_restore
    project&.namespace&.propagate_samples_count_delta(1)
  end

  # Propagate samples_count transfer when sample is moved to a different project.
  def propagate_samples_count_on_transfer # rubocop:disable Metrics/CyclomaticComplexity
    return unless saved_change_to_project_id?

    old_project_id = saved_change_to_project_id[0]
    new_project_id = saved_change_to_project_id[1]

    # Decrement old project's ancestors
    old_project = Project.find(old_project_id) if old_project_id
    old_project&.namespace&.propagate_samples_count_delta(-1)

    # Increment new project's ancestors
    new_project = Project.find(new_project_id) if new_project_id
    new_project&.namespace&.propagate_samples_count_delta(1)
  end

  # Propagate samples_count decrement when sample is destroyed.
  def propagate_samples_count_on_destroy
    return if destroyed_by_association

    # Decrement project's ancestors when sample is deleted
    project&.namespace&.propagate_samples_count_delta(-1)
  end

  def broadcast_refresh_later_to_samples_table # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if Sample.suppressed_turbo_broadcasts

    projects = project && !project.deleted? ? [project] : []

    if previous_changes['project_id'] && !previous_changes['project_id'][0].nil?
      projects << Project.find(previous_changes['project_id'][0])
    end

    projects.each do |proj|
      next if proj&.deleted?

      proj.broadcast_refresh_later_to_samples_table
    end
  end
end
