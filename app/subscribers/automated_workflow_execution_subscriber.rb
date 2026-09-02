# frozen_string_literal: true

# Subscriber for automated workflow execution events. This subscriber listens for events related to automated workflow
# executions and triggers the AutomatedWorkflowExecutions::LaunchJob.
class AutomatedWorkflowExecutionSubscriber
  PAIRED_END_TYPES = %w[illumina_pe pe].freeze

  def emit(event) # rubocop:disable Metrics/AbcSize
    return unless event[:name] == 'attachments.create'
    return unless Irida::Pipelines.instance.pipelines.any? &&
                  event[:payload][:attachable].instance_of?(Sample)

    attachable = event[:payload][:attachable]
    attachments = event[:payload][:attachments]

    return if attachments.blank?

    paired_end = paired_end_attachments(attachments)
    return unless paired_end.any?

    return if event[:payload][:attachable].project.namespace.automated_workflow_executions.blank?

    # Trigger the automated workflow execution
    AutomatedWorkflowExecutions::LaunchJob.perform_later(attachable, paired_end.last)
  end

  private

  def paired_end_attachments(attachments)
    paired_end = []
    paired_end_existing_ids = Set.new

    attachments.each do |attachment|
      next if already_processed_or_attachment_blank?(attachment, paired_end_existing_ids)

      associated_attachment = find_associated_attachment(attachment)
      next unless associated_attachment && paired_end_type?(associated_attachment)

      paired_end << { 'forward' => attachment, 'reverse' => associated_attachment }
      paired_end_existing_ids.add(attachment.id)
      paired_end_existing_ids.add(associated_attachment.id)
    end

    paired_end
  end

  def already_processed_or_attachment_blank?(attachment, paired_end_existing_ids)
    paired_end_existing_ids.include?(attachment.id) ||
      attachment.metadata['associated_attachment_id'].blank?
  end

  def find_associated_attachment(attachment)
    associated_id = attachment.metadata['associated_attachment_id']
    Attachment.find_by(id: associated_id)
  end

  def paired_end_type?(attachment)
    PAIRED_END_TYPES.include?(attachment.metadata['type'])
  end
end
