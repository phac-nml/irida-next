# frozen_string_literal: true

module Attachments
  # Service used to Create Attachments
  class CreateService < BaseService # rubocop:disable Metrics/ClassLength
    attr_accessor :attachable, :attachments, :pe_attachments

    class AttachmentsCreateError < StandardError
    end

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)

      @attachable = attachable
      @attachments = []
      @pe_attachments = []

      @include_activity = params.key?(:include_activity) ? params[:include_activity] : true

      return unless params.key?(:files)

      params[:files].each do |file|
        @attachments << Attachment.new(attachable:, file:) if file.present?
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      @attachable.errors.add(:base, "#{e.message}: Invalid blob id")
      @attachments
    rescue ActiveStorage::FileNotFoundError => e
      @attachable.errors.add(:base, "#{e.message}: Blob is empty, no file found.")
      @attachments
    end

    def execute # rubocop:disable Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/MethodLength
      validate_project_not_archived(attachable.project.namespace) if attachable.instance_of?(Sample)
      attachable_authorization

      ActiveRecord::Base.transaction do
        valid_fastq_attachments = @attachments.select { |attachment| attachment.valid? && attachment.fastq? }

        identify_illumina_paired_end_files(valid_fastq_attachments) if valid_fastq_attachments.many?

        unidentified_fastq_attachments = valid_fastq_attachments.reject do |attachment|
          attachment.metadata['type'] == 'illumina_pe'
        end

        identify_paired_end_files(unidentified_fastq_attachments) if unidentified_fastq_attachments.many?

        @attachments.each(&:save)

        create_activities if @include_activity

        if Irida::Pipelines.instance.pipelines.any? &&
           @attachable.instance_of?(Sample) &&
           @attachable.project.namespace.automated_workflow_executions.present?
          launch_automated_workflow_executions(@pe_attachments&.last)
        end
      end

      @attachments
    rescue Attachments::CreateService::AttachmentsCreateError => e
      @attachable.errors.add(:base, e.message)
      @attachments
    end

    private

    def create_activities # rubocop:disable Metrics/MethodLength
      if @attachable.instance_of?(Sample)
        attachable_object = @attachable.project.namespace
        activity_key = 'namespaces_project_namespace.samples.attachment.create'
        params = {
          sample_puid: @attachable.puid,
          sample_id: @attachable.id,
          action: 'attachment_create'
        }
      elsif @attachable.instance_of?(Namespaces::ProjectNamespace)
        attachable_object = @attachable
        activity_key = 'namespaces_project_namespace.attachment.create'
        params = {
          action: 'project_attachment_create'
        }
      elsif @attachable.instance_of?(Group)
        attachable_object = @attachable
        activity_key = 'group.attachment.create'
        params = {
          action: 'group_attachment_create'
        }
      end

      return unless attachable_object

      attachable_object.create_activity key: activity_key,
                                        owner: current_user,
                                        trackable_id: @attachable.id,
                                        parameters: params
    end

    def attachable_authorization
      if @attachable.instance_of?(Sample)
        authorize! @attachable.project, to: :update_sample?
      elsif @attachable.instance_of?(Namespaces::ProjectNamespace)
        authorize! @attachable.project, to: :create_attachment?
      elsif @attachable.instance_of?(Group)
        authorize! @attachable, to: :create_attachment?
      end
    end

    def identify_illumina_paired_end_files(attachments)
      # auto-vivify hash, as found on stack overflow http://stackoverflow.com/questions/5878529/how-to-assign-hashab-c-if-hasha-doesnt-exist
      illumina_pe = Hash.new { |h, k| h[k] = {} }

      # identify illumina pe attachments based on illumina fastq filename convention
      # https://support.illumina.com/help/BaseSpace_OLH_009008/Content/Source/Informatics/BS/NamingConvention_FASTQ-files-swBS.htm
      attachments.each do |att|
        pairing_info = Attachment.fastq_illumina_pe_pairing_info(att.filename.to_s)
        next unless pairing_info

        illumina_pe[pairing_info.pair_key][pairing_info.direction] = att
      end

      # assign metadata to detected illumina pe files that contain fwd and rev
      assign_metadata(illumina_pe, 'illumina_pe')
    end

    def identify_paired_end_files(attachments)
      # auto-vivify hash, as found on stack overflow http://stackoverflow.com/questions/5878529/how-to-assign-hashab-c-if-hasha-doesnt-exist
      pe = Hash.new { |h, k| h[k] = {} }

      # identify pe attachments based on fastq filename convention
      attachments.each do |att|
        pairing_info = Attachment.fastq_pe_pairing_info(att.filename.to_s)
        next unless pairing_info

        pe[pairing_info.pair_key][pairing_info.direction] = att
      end

      # assign metadata to detected pe files that contain fwd and rev
      assign_metadata(pe, 'pe')
    end

    def assign_metadata(paired_ends, type) # rubocop:disable Metrics/AbcSize
      paired_ends.each do |key, pe_attachments|
        next unless pe_attachments.key?('forward') && pe_attachments.key?('reverse')

        # assign the PUID to be same for forward and reverse and then save so that we have the ids
        assign_pe_attachments_puid(pe_attachments)

        fwd_metadata = {
          associated_attachment_id: pe_attachments['reverse'].id, type:, direction: 'forward'
        }

        pe_attachments['forward'].metadata = pe_attachments['forward'].metadata.merge(fwd_metadata)

        rev_metadata = {
          associated_attachment_id: pe_attachments['forward'].id, type:, direction: 'reverse'
        }

        pe_attachments['reverse'].metadata = pe_attachments['reverse'].metadata.merge(rev_metadata)

        @pe_attachments << paired_ends[key]
      end
    end

    def assign_pe_attachments_puid(pe_attachments)
      puid = Irida::PersistentUniqueId.generate(pe_attachments['forward'], time: Time.now) # rubocop:disable Rails/TimeZone
      pe_attachments['forward'].puid = puid
      pe_attachments['reverse'].puid = puid
      pe_attachments['forward'].save
      pe_attachments['reverse'].save
    end

    def launch_automated_workflow_executions(pe_attachment_pair)
      unless pe_attachment_pair.present? && pe_attachment_pair.key?('forward') && pe_attachment_pair.key?('reverse')
        return
      end

      AutomatedWorkflowExecutions::LaunchJob.perform_later(@attachable, pe_attachment_pair)
    end
  end
end
