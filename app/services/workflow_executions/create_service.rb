# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Create a new WorkflowExecution
  class CreateService < BaseService # rubocop:disable Metrics/ClassLength
    attr_accessor :workflow, :samplesheet_properties

    def initialize(user = nil, params = {})
      super
      @workflow = Irida::Pipelines.instance.find_pipeline_by(params[:metadata][:pipeline_id],
                                                             params[:metadata][:workflow_version])

      return unless @workflow && !@workflow.unknown?

      @samplesheet_properties = Irida::Nextflow::Samplesheet::Properties.new(
        @workflow.workflow_params[:input_output_options][:properties][:input][:schema]
      )
    end

    def execute
      return false if params.empty?

      initialize_workflow_execution

      add_workflow_execution_tags

      return @workflow_execution unless @workflow_execution.valid?

      assign_workflow_params

      # Check if required number of samples (min/max) is set for pipeline and set error to
      # non persisted workflow execution object if selected samples exceeds/doesn't meet this requirement
      validate_samples_requirement_for_pipeline(@workflow_execution)

      autoset_samplesheet_params
      validate_samplesheet_params

      persist_workflow_execution
      queue_preparation_job

      @workflow_execution
    end

    def initialize_workflow_execution
      autoset_params if @workflow
      @workflow_execution = WorkflowExecution.new(params.except(:samples_workflow_executions_attributes))

      authorize! @workflow_execution.namespace, to: :submit_workflow?

      @workflow_execution.submitter = current_user
      @samples_count = samples_workflow_execution_attributes.length
    end

    def assign_workflow_params
      return unless params.key?(:workflow_params)

      @workflow_execution.workflow_params = sanitized_workflow_params
    end

    def persist_workflow_execution
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @workflow_execution.errors.empty?

        @workflow_execution.save!
        insert_samples_workflow_executions
      end
    end

    def insert_samples_workflow_executions
      SamplesWorkflowExecution.insert_all( # rubocop:disable Rails/SkipsModelValidations
        @samplesheet_params.map do |params|
          params.merge(workflow_execution_id: @workflow_execution.id)
        end,
        record_timestamps: true
      )
    end

    def queue_preparation_job
      return unless @workflow_execution.errors.empty? && @workflow_execution.persisted?

      create_activities
      WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
    end

    def add_workflow_execution_tags
      @workflow_execution.tags = if Flipper.enabled?(:wes_extended_metadata)
                                   { createdBy: current_user.email, namespaceId: @workflow_execution.namespace.puid,
                                     samplesCount: @samples_count.to_s }
                                 else
                                   { createdBy: current_user.email }
                                 end
    end

    def sanitized_workflow_params
      # remove any nil values
      sanitized_params = params[:workflow_params].compact

      workflow.workflow_params.each_value do |definition|
        definition[:properties].each do |name, property|
          if sanitized_params.key?(name.to_sym)
            sanitized_params[name.to_sym] = sanitize_workflow_param(property, sanitized_params[name.to_sym])
          end
        end
      end

      sanitized_params
    end

    def autoset_params
      params.merge!(@workflow.default_params)

      return if @workflow.default_workflow_params.empty?

      params['workflow_params'].reverse_merge!(@workflow.default_workflow_params)
    end

    def samples_workflow_execution_attributes
      attributes = params[:samples_workflow_executions_attributes]

      return attributes if attributes.is_a?(Array)

      attributes.values
    end

    def sanitize_workflow_param(property, value)
      case property[:type]
      when 'integer'
        value.to_i
      when 'number'
        value.to_f
      when 'boolean'
        ActiveModel::Type::Boolean.new.cast(value)
      else
        value
      end
    end

    def validate_samples_requirement_for_pipeline(workflow_execution)
      min_samples = workflow_execution.workflow.minimum_samples
      max_samples = workflow_execution.workflow.maximum_samples
      if @samples_count < min_samples
        workflow_execution.errors.add(:base,
                                      I18n.t('services.workflow_executions.create.min_samples_required',
                                             min_samples: min_samples))
      end
      return unless max_samples.positive? && (@samples_count > max_samples)

      workflow_execution.errors.add(:base,
                                    I18n.t('services.workflow_executions.create.max_samples_exceeded',
                                           max_samples: max_samples))
    end

    def create_activities
      return unless @workflow_execution.submitter.automation_bot?

      @workflow_execution.namespace.create_activity key: 'workflow_execution.automated_workflow.launch',
                                                    owner: current_user,
                                                    parameters:
                                                    {
                                                      workflow_id: @workflow_execution.id,
                                                      workflow_name: @workflow_execution.name,
                                                      sample_id:
                                                      @workflow_execution.samples_workflow_executions.first.sample.id,
                                                      sample_puid:
                                                      @workflow_execution.samples_workflow_executions.first.sample.puid
                                                    }
    end

    def autoset_samplesheet_params
      has_sample_name_param = @samplesheet_properties.properties.key?('sample_name')
      @samplesheet_params = samples_workflow_execution_attributes.each_slice(1000).flat_map do |batch|
        build_samplesheet_batch(batch, has_sample_name_param)
      end
    end

    def build_samplesheet_batch(batch, has_sample_name_param)
      sample_ids = batch.pluck(:sample_id)
      batch_samples = Sample.where(id: sample_ids).select(:id, :puid, :name).index_by(&:id)

      batch.map do |swe_params|
        sample = batch_samples[swe_params[:sample_id]]
        next swe_params unless sample

        swe_params.with_indifferent_access
                  .slice(:sample_id, :samplesheet_params)
                  .deep_merge(samplesheet_params: {
                    sample: sample.puid,
                    sample_name: has_sample_name_param ? sample.name : nil
                  }.compact)
      end
    end

    def validate_samplesheet_params
      file_cell_properties = @samplesheet_properties.properties.select do |_property, entry|
        Irida::Nextflow::Samplesheet::Properties::FILE_CELL_TYPES.include?(entry['cell_type'])
      end

      @samplesheet_params.each_slice(1000) do |batch|
        validate_file_cells_in_batch(batch, file_cell_properties)
      end
    end

    def validate_file_cells_in_batch(batch, file_cell_properties)
      file_cell_properties.each do |property, entry|
        attachments = locate_batch_attachments(batch, property)

        batch.each do |params|
          validate_file_cell(params:, property:, entry:, attachments:)
        end
      end
    end

    def locate_batch_attachments(batch, property)
      GlobalID::Locator.locate_many(batch.map do |params|
        GlobalID.parse(params[:samplesheet_params][property])
      end.compact, only: Attachment, ignore_missing: true).index_by(&:id)
    end

    def validate_file_cell(params:, property:, entry:, attachments:)
      sample_id = params[:sample_id]
      sample_puid = params[:samplesheet_params][:sample]
      value = params[:samplesheet_params][property]

      return if missing_optional_value?(value, entry, property, sample_puid)

      gid = parse_gid(value, property, sample_puid)
      return unless gid

      attachment = attachments[gid.model_id]
      return unless valid_sample_attachment_or_add_error?(attachment, sample_id, property, sample_puid)
      return if valid_file_format?(attachment, entry)

      add_file_cell_error('attachment_format_error', property:, sample_puid:, file_format: entry['pattern'])
    end

    def missing_optional_value?(value, entry, property, sample_puid)
      return false if value.present?

      add_file_cell_error('blank_error', property:, sample_puid:) if entry['required']
      true
    end

    def parse_gid(value, property, sample_puid)
      gid = GlobalID.parse(value)
      return gid if gid

      add_file_cell_error('attachment_gid_error', property:, sample_puid:)
      nil
    end

    def valid_sample_attachment_or_add_error?(attachment, sample_id, property, sample_puid)
      return true if valid_sample_attachment?(attachment, sample_id)

      add_file_cell_error('sample_attachment_error', property:, sample_puid:)
      false
    end

    def valid_sample_attachment?(attachment, sample_id)
      attachment.present? && attachment.attachable_id == sample_id && attachment.attachable_type == 'Sample'
    end

    def valid_file_format?(attachment, entry)
      case entry['cell_type']
      when 'fastq_cell'
        attachment.fastq?
      when 'file_cell'
        return true unless entry['pattern']

        attachment.filename.to_s.match?(entry['pattern'])
      else
        true
      end
    end

    def add_file_cell_error(error_key, property:, sample_puid:, file_format: nil)
      error_options = { property:, sample_id: sample_puid }
      error_options[:file_format] = file_format if file_format

      @workflow_execution.errors.add(
        :base,
        I18n.t("validators.workflow_execution_samplesheet_params_validator.#{error_key}", **error_options)
      )
    end
  end
end
