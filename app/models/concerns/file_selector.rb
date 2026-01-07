# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector
  extend ActiveSupport::Concern

  def file_selector_fastq_files(property)
    fastq_files = query_fastq_files(property == 'fastq_1' ? 'forward' : 'reverse', property == 'fastq_1')
    return unless fastq_files

    fastq_files.map do |file|
      file_selector_attributes(file)
    end
  end

  def file_selector_other_files(pattern)
    other_files = if pattern
                    query_files_by_pattern(pattern)
                  else
                    query_non_fastq_files
                  end
    other_files.map do |file|
      file_selector_attributes(file)
    end
  end

  def most_recent_fastq_files
    # prioritize paired attachment before returning single attachment
    forward_file = query_fastq_files('forward', false).first

    if forward_file
      { 'fastq_1' => samplesheet_file_attributes(forward_file),
        'fastq_2' => samplesheet_file_attributes(forward_file.associated_attachment) }
    else
      single_file = query_single_fastq_files.first
      if single_file
        { 'fastq_1' => samplesheet_file_attributes(single_file), 'fastq_2' => {} }
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

    samplesheet_file_attributes(most_recent_file)
  end

  private

  def samplesheet_file_attributes(file)
    {
      filename: file.file.filename.to_s,
      global_id: file.to_global_id,
      id: file.id
    }
  end

  def file_selector_attributes(attachment)
    {
      filename: attachment.file.filename.to_s,
      global_id: attachment.to_global_id,
      id: attachment.id,
      byte_size: attachment.byte_size,
      created_at: attachment.created_at,
      metadata: attachment.metadata
    }
  end

  def create_query_node(key)
    Arel::Nodes::InfixOperation.new('->>', Attachment.arel_table[:metadata],
                                    Arel::Nodes::Quoted.new(key))
  end

  # paired fastq files of single direction
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

  def query_non_fastq_files
    node = create_query_node('format')
    attachments.where(node.not_eq('fastq')).order(created_at: :desc, id: :desc)
  end
end
