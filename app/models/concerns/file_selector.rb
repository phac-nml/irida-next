# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector
  extend ActiveSupport::Concern

  def file_selector_fastq_files(property)
    fastq_files = query_fastq_files(property == 'fastq_1' ? 'forward' : 'reverse', property == 'fastq_1')
    return unless fastq_files

    fastq_files.map do |file|
      file_attributes(file, 'file_selector')
    end
  end

  # TODO: verify how pattern comes in if no pattern
  def file_selector_other_files(pattern)
    other_files = if pattern
                    query_files_by_pattern(pattern)
                  else
                    query_non_fastq_files
                  end
    other_files.map do |file|
      file_attributes(file, 'file_selector')
    end
  end

  def most_recent_fastq_files
    # prioritize paired attachment before returning single attachment
    forward_file = query_fastq_files('forward', false).first

    if forward_file
      { 'fastq_1' => file_attributes(forward_file, 'samplesheet'),
        'fastq_2' => file_attributes(forward_file.associated_attachment, 'samplesheet') }
    else
      single_file = query_single_fastq_files.order(created_at: :desc, id: :desc).first
      if single_file
        { 'fastq_1' => file_attributes(single_file, 'samplesheet'), 'fastq_2' => {} }
      else
        { 'fastq_1' => {}, 'fastq_2' => {} }
      end
    end
  end

  def most_recent_other_file(autopopulate, pattern)
    return {} unless autopopulate

    most_recent_file = if pattern
                         # find file that fits regex
                         query_files_by_pattern(pattern).first
                       else
                         # find file that is not fastq
                         query_non_fastq_files.first
                       end

    return {} unless most_recent_file

    file_attributes(most_recent_file, 'samplesheet')
  end

  private

  # return the necessary file attributes, format currently == 'samplesheet' or 'file_selector'
  def file_attributes(file, format)
    attributes = {
      filename: file.file.filename.to_s,
      global_id: file.to_global_id,
      id: file.id
    }

    return attributes unless format == 'file_selector'

    attributes.merge({
                       byte_size: attachment.byte_size,
                       created_at: attachment.created_at,
                       metadata: attachment.metadata
                     })
  end

  def create_query_node(key)
    Arel::Nodes::InfixOperation.new('->>', Attachment.arel_table[:metadata],
                                    Arel::Nodes::Quoted.new(key))
  end

  # queries fastq files for what's displayed in the samplesheet and file_selector of the samplesheet
  # param direction (string): query specific direction
  # param include_singles (boolean):
  #   - false when querying for what's displayed in samplesheet (if no PE attachment found, samplesheet will perform
  #   a separate query to find first non-PE single)
  #   - true when querying file_selector fastq files, specifically for forward direction. This query will include both
  #   all PE forward files and any non-pe fastq files.
  def query_fastq_files(direction, include_singles)
    direction_node = create_query_node('direction')
    associated_attachment_node = create_query_node('associated_attachment_id')

    paired_files = attachments.where(
      direction_node.eq(direction),
      associated_attachment_node.not_eq(nil)
    )

    return paired_files.order(created_at: :desc, id: :desc) unless include_singles

    single_files = query_single_fastq_files
    paired_files.or(single_files).order(created_at: :desc, id: :desc)
  end

  # single non-paired fastq files
  def query_single_fastq_files
    format_node = create_query_node('format')
    associated_attachment_node = create_query_node('associated_attachment_id')
    attachments.where(format_node.eq('fastq')).where(
      associated_attachment_node.eq(nil)
    )
  end

  def query_files_by_pattern(pattern)
    attachments
      .joins(:file_blob)
      .where(ActiveStorage::Blob.arel_table[:filename].matches_regexp(pattern))
      .order(created_at: :desc, id: :desc)
  end

  # query all non-fastq files when no pattern is specified.
  def query_non_fastq_files
    node = create_query_node('format')
    attachments.where(node.not_eq('fastq')).order(created_at: :desc, id: :desc)
  end
end
