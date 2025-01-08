# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector
  extend ActiveSupport::Concern

  def sorted_files
    return {} if attachments.empty?

    @sorted_files || sort_files
  end

  def sort_files # rubocop:disable Metrics/MethodLength
    singles = []
    pe_forward = []
    pe_reverse = []

    attachments.each do |attachment|
      item = {
        filename: attachment.file.filename.to_s,
        global_id: attachment.to_global_id,
        id: attachment.id,
        byte_size: attachment.byte_size,
        created_at: attachment.created_at
      }
      case attachment.metadata['direction']
      when nil
        singles << item
      when 'forward'
        pe_forward << item
      else
        pe_reverse << item
      end
    end

    @sorted_files = { singles:, pe_forward:, pe_reverse: }
    @sorted_files
  end

  def samplesheet_fastq_files(property, workflow_params)
    direction = fastq_direction(property)
    pattern = retrieve_pattern(property, workflow_params)
    singles = filter_files_by_pattern(sorted_files[:singles] || [], pattern || "/^\S+.f(ast)?q(.gz)?$/")
    files = []
    if sorted_files[direction].present?
      files = sorted_files[direction] || []
      files.concat(singles) if property['pe_only'].blank?
    else
      files = singles
    end
    (files.sort_by! { |file| file[:created_at] }).reverse
  end

  def most_recent_file(file_type, **system_arguments)
    if file_type == 'fastq'
      most_recent_fastq_file(system_arguments[:property], system_arguments[:workflow_params])
    elsif file_type == 'other'
      most_recent_other_file(system_arguments[:autopopulate], system_arguments[:pattern])
    end
  end

  # separate function from samplesheet_fastq_files since this function would prefer selection of latest paired_end
  # attachments, where as samplesheet_fastq_files will return the overall latest attachment (ie: possibly a single)
  def most_recent_fastq_file(property, workflow_params)
    direction = fastq_direction(property)

    if sorted_files[direction].present?
      sorted_files[direction].last
    else
      pattern = retrieve_pattern(property, workflow_params)
      last_single = filter_files_by_pattern(sorted_files[:singles] || [], pattern || "/^\S+.f(ast)?q(.gz)?$/").last
      last_single.nil? ? {} : last_single
    end
  end

  def most_recent_other_file(autopopulate, pattern)
    return {} unless autopopulate

    files = if pattern
              filter_files_by_pattern(sorted_files[:singles] || [], pattern)
            else
              sorted_files[:singles] || []
            end
    files.present? ? files.last : {}
  end

  def filter_files_by_pattern(files, pattern)
    files.select { |file| file[:filename] =~ Regexp.new(pattern) }
  end

  private

  def fastq_direction(property)
    property.match(/fastq_(\d+)/)[1].to_i == 1 ? :pe_forward : :pe_reverse
  end

  def retrieve_pattern(property, workflow_params)
    pipeline = Irida::Pipelines.instance.find_pipeline_by(workflow_params[:name], workflow_params[:version])
    return nil unless pipeline

    pipeline.property_pattern(property)
  end
end
