# frozen_string_literal: true

# MetadataTemplate represents a template for structured metadata fields
class MetadataTemplate < ApplicationRecord
  include TrackActivity

  METADATA_TEMPLATE_JSON_SCHEMA = Rails.root.join('config/schemas/metadata_template_metadata.json')

  has_logidze
  acts_as_paranoid

  # Associations
  belongs_to :created_by, class_name: 'User'

  # Validations
  validates :name, presence: true, uniqueness: { scope: [:namespace_id] }
  validates :description, length: { maximum: 1000 }

  belongs_to :namespace, autosave: true

  belongs_to :group, optional: true, foreign_key: :namespace_id # rubocop:disable Rails/InverseOf
  belongs_to :project_namespace, optional: true, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  validates :fields, presence: true, uniqueness: { scope: [:namespace_id] }, json: { message: lambda { |errors|
    errors.map { |error| MetadataTemplate.format_json_error(error) }
  }, schema: METADATA_TEMPLATE_JSON_SCHEMA }

  validate :validate_namespace

  def self.ransackable_attributes(_auth_object = nil)
    %w[name created_at description updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[created_by namespace]
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def self.format_json_error(error)
    case error['type']
    when 'maxItems'
      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.max_items',
             max: error['schema']['maxItems'])
    when 'minItems'
      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_items',
             min: error['schema']['minItems'])
    when 'uniqueItems'
      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.unique_items')
    when 'minLength'
      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.min_length',
             min: error['schema']['minLength'])
    else
      # Provide more context for unexpected errors
      details = error['details'] || error['message']
      return details if details.present?

      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.invalid',
             error_type: error['type'] || 'unknown')
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  private

  def validate_namespace
    # Only Groups and Projects should have metadata templates
    return if %w[Group Project].include?(namespace.type)

    errors.add(namespace.type, 'namespace cannot have metadata templates')
  end
end
