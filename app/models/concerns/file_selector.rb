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
  # param include_singles (boolean): whether to include files without a direction (i.e. single end fastq files)
  #  - This is ignored if direction is 'reverse' since single end files should only be included with forward direction
  # returns an ActiveRecord::Relation of matching attachments
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
