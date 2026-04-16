# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector
  extend ActiveSupport::Concern

  def file_selector_fastq_files(property, pattern, pe_only)
    fastq_files = query_fastq_files(property == 'fastq_1' ? 'forward' : 'reverse', pattern,
                                    property == 'fastq_1' && !pe_only)
    return unless fastq_files

    fastq_files.map do |file|
      file_attributes(file, 'file_selector')
    end
  end

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

  private

  # TODO: Remove fastq_direction when v2_samplesheet is retired
  def fastq_direction(property)
    case property.match(/^fastq_(\d+)$/).to_a[1]
    when '1'
      :pe_forward
    when '2'
      :pe_reverse
    else
      :single
    end
  end

  # return the necessary file attributes, format currently == 'samplesheet' or 'file_selector'
  def file_attributes(file, format)
    attributes = {
      filename: file.file.filename.to_s,
      global_id: file.to_global_id,
      id: file.id
    }

    return attributes unless format == 'file_selector'

    attributes.merge({
                       byte_size: file.byte_size,
                       created_at: file.created_at,
                       metadata: file.metadata
                     })
  end

  # queries fastq files for what's displayed in the samplesheet and file_selector of the samplesheet
  # param direction (string): query specific direction
  # param include_singles (boolean):
  #   - false when querying for what's displayed in samplesheet (if no PE attachment found, samplesheet will perform
  #   a separate query to find first non-PE single)
  #   - true when querying file_selector fastq files, specifically for forward direction. This query will include both
  #   all PE forward files and any non-pe fastq files.
  def query_fastq_files(direction, pattern, include_singles)
    attachments
      .matching_filename(pattern)
      .with_direction(direction, include_nils: include_singles)
      .prefer_associated_attachment
      .recent
  end

  def query_files_by_pattern(pattern)
    attachments
      .matching_filename(pattern)
      .recent
  end

  # query all non-fastq files when no pattern is specified.
  def query_non_fastq_files
    attachments.where(Attachment.metadata_arel_node('format').not_eq('fastq')).recent
  end
end
