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
        created_at: attachment.created_at,
        metadata: attachment.metadata
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

  def samplesheet_fastq_files(property, pattern)
    direction = fastq_direction(property)
    singles = filter_files_by_pattern(sorted_files[:singles] || [], pattern || "/^\S+.f(ast)?q(.gz)?$/")
    files = sorted_files.fetch(direction, [])

    files.concat(singles) if (direction == :pe_forward && property['pe_only'].blank?) || direction == :none
    (files.sort_by! { |file| file[:created_at] }).reverse
  end

  # separate function from samplesheet_fastq_files since this function would prefer selection of latest paired_end
  # attachments, where as samplesheet_fastq_files will return the overall latest attachment (ie: possibly a single)
  def most_recent_fastq_file(property, pattern)
    direction = fastq_direction(property)

    if sorted_files[direction].present?
      sorted_files[direction].last
    elsif %i[pe_forward none].include?(direction)
      last_single = filter_files_by_pattern(sorted_files[:singles] || [], pattern || "/^\S+.f(ast)?q(.gz)?$/").last
      last_single.nil? ? {} : last_single
    else
      {}
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
    case property.match(/^fastq_(\d+)$/).to_a[1]
    when '1'
      :pe_forward
    when '2'
      :pe_reverse
    else
      :single
    end
  end
end
