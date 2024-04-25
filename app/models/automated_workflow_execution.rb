# frozen_string_literal: true

# entity class for Automated Workflow Executions
class AutomatedWorkflowExecution < ApplicationRecord
  METADATA_JSON_SCHEMA = Rails.root.join('config/schemas/workflow_execution_metadata.json')

  has_logidze

  belongs_to :namespace
  belongs_to :created_by, class_name: 'User'

  belongs_to :project_namespace, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  validates :metadata, presence: true, json: { message: ->(errors) { errors }, schema: METADATA_JSON_SCHEMA }

  validate :validate_namespace_type

  private

  def validate_namespace_type
    # Only Projects should have automated workflow executions
    return if %w[Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have automated workflow executions')
  end

  def higher_access_level_than_group
    return unless highest_group_member && highest_group_member.access_level > access_level

    errors.add(:access_level, I18n.t('activerecord.errors.models.member.attributes.access_level.invalid',
                                     user: user.email,
                                     access_level: AccessLevel.human_access(highest_group_member.access_level),
                                     group_name: highest_group_member.group.name))
  end
end
