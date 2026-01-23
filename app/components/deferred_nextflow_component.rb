# frozen_string_literal: true

# Component to render Nextflow pipeline forms
class DeferredNextflowComponent < Component
  include NextflowHelper

  attr_reader :url, :workflow, :metadata_fields, :sample_count, :namespace_id, :instance, :automated_workflow

  # rubocop:disable Metrics/ParameterLists
  def initialize(url:, sample_count:, workflow:, fields:, namespace_id:, instance: nil)
    @sample_count = sample_count
    @automated_workflow = @sample_count.nil? || @sample_count.zero?
    @namespace_id = namespace_id
    @url = url
    @workflow = workflow
    @metadata_fields = fields
    @instance = instance
    @namespace_type = namespace_type(namespace_id)
  end
  # rubocop:enable Metrics/ParameterLists

  def namespace_type(namespace_id)
    namespace = Namespace.find_by(id: namespace_id)
    return unless namespace

    namespace.type
  end

  def label_attributes(condition)
    attributes = {}
    if condition
      attributes[:name] = t('components.nextflow_component.name.label.required')
      attributes[:data] = { required: true }
    else
      attributes[:name] = t('components.nextflow_component.name.label.optional')
      attributes[:data] = {}
    end
    attributes
  end
end
