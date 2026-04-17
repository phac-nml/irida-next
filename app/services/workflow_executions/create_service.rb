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

    def execute # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return false if params.empty?

      autoset_params if @workflow
      @workflow_execution = WorkflowExecution.new(params.except(:samples_workflow_executions_attributes))

      authorize! @workflow_execution.namespace, to: :submit_workflow?

      @workflow_execution.submitter = current_user

      @samples_count = if params[:samples_workflow_executions_attributes].is_a?(Array)
                         params[:samples_workflow_executions_attributes].length
                       else
                         params[:samples_workflow_executions_attributes].keys.length
                       end

      add_workflow_execution_tags

      return @workflow_execution unless @workflow_execution.valid?

      if @workflow_execution.valid? && params.key?(:workflow_params)
        @workflow_execution.workflow_params = sanitized_workflow_params
      end

      # Check if required number of samples (min/max) is set for pipeline and set error to
      # non persisted workflow execution object if selected samples exceeds/doesn't meet this requirement
      validate_samples_requirement_for_pipeline(@workflow_execution)

      autoset_samplesheet_params
      validate_samplesheet_params

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @workflow_execution.errors.empty?

        @workflow_execution.save

        SamplesWorkflowExecution.insert_all( # rubocop:disable Rails/SkipsModelValidations
          @samplesheet_params.map do |params|
            params.merge(workflow_execution_id: @workflow_execution.id)
          end,
          record_timestamps: true
        )
      end

      if @workflow_execution.errors.empty? && @workflow_execution.persisted?
        create_activities
        WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
      end

      @workflow_execution
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

    def autoset_samplesheet_params # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      has_sample_name_param = @samplesheet_properties.properties.key?('sample_name')
      samples_workflow_executions_attributes = if params[:samples_workflow_executions_attributes].is_a?(Array)
                                                 params[:samples_workflow_executions_attributes]
                                               else
                                                 params[:samples_workflow_executions_attributes].values
                                               end

      @samplesheet_params = samples_workflow_executions_attributes.each_slice(1000).map do |batch|
        batch_samples = Sample.where(id: batch.map { |attr| attr[:sample_id] }).select(:id, :puid, :name).index_by(&:id)

        batch.map do |swe_params|
          sample = batch_samples[swe_params[:sample_id]]

          return swe_params unless sample

          swe_params.with_indifferent_access
                    .slice(:sample_id, :samplesheet_params)
                    .deep_merge(samplesheet_params: {
                      sample: sample.puid,
                      sample_name: has_sample_name_param ? sample.name : nil
                    }.compact)
        end
      end.flatten
    end

    def validate_samplesheet_params # rubocop:disable Metrics/AbcSize
      file_cell_properties = @samplesheet_properties.properties.select do |_property, entry|
        Irida::Nextflow::Samplesheet::Properties::FILE_CELL_TYPES.include?(entry['cell_type'])
      end

      @samplesheet_params.each_slice(1000) do |batch|
        file_cell_properties.each do |property, entry|
          attachments = GlobalID::Locator.locate_many(batch.map do |params|
            GlobalID.parse(params[:samplesheet_params][property])
          end.compact, only: Attachment, ignore_missing: true).index_by(&:id)

          batch.each do |params|
            value = params[:samplesheet_params][property]

            validate_file_cell(params[:sample_id], params[:samplesheet_params][:sample], value, property, entry,
                               attachments)
          end
        end
      end
    end

    def validate_file_cell(sample_id, sample_puid, value, property, entry, attachments) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/ParameterLists
      if value.blank?
        if entry['required']
          @workflow_execution.errors.add(
            :base,
            I18n.t('validators.workflow_execution_samplesheet_params_validator.blank_error',
                   property: property, sample_id: sample_puid)
          )
        end

        return
      end

      gid = GlobalID.parse(value)

      unless gid
        @workflow_execution.errors.add(
          :base,
          I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_gid_error',
                 property: property, sample_id: sample_puid)
        )

        return
      end

      attachment = attachments[gid.model_id]

      unless attachment.attachable_id == sample_id && attachment.attachable_type == 'Sample'
        @workflow_execution.errors.add(
          :base,
          I18n.t('validators.workflow_execution_samplesheet_params_validator.sample_attachment_error',
                 property: property, sample_id: sample_puid)
        )

        return
      end

      valid = true

      case entry['cell_type']
      when 'fastq_cell'
        valid = attachment.fastq?
      when 'file_cell'
        valid = attachment.filename.to_s.match?(entry['pattern']) if entry['pattern']
      end

      return if valid

      @workflow_execution.errors.add(
        :base,
        I18n.t('validators.workflow_execution_samplesheet_params_validator.attachment_format_error',
               property: property, sample_id: sample_puid, file_format: entry['pattern'])
      )
    end
  end
end
