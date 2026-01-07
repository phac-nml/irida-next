# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  def sorted_files
    return {} if attachments.empty?

    @sorted_files || sort_files
  end

  def sort_files # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    singles = []
    pe_forward = []
    pe_reverse = []
    node = Arel::Nodes::InfixOperation.new('->>', Attachment.arel_table[:metadata],
                                           Arel::Nodes::Quoted.new('direction'))
    non_reverse_attachments = attachments.where(node.eq(nil).or(node.not_eq('reverse'))).order(:created_at, :id)

    non_reverse_attachments.each do |attachment|
      case attachment.metadata['direction']
      when nil
        singles << retrieve_attachment_attributes(attachment)
      when 'forward'
        pe_forward << retrieve_attachment_attributes(attachment)
        pe_reverse << retrieve_attachment_attributes(attachment.associated_attachment)
      end
    end

    @sorted_files = { singles:, pe_forward:, pe_reverse: }
    @sorted_files
  end

  def retrieve_attachment_attributes(attachment)
    {
      filename: attachment.file.filename.to_s,
      global_id: attachment.to_global_id,
      id: attachment.id,
      byte_size: attachment.byte_size,
      created_at: attachment.created_at,
      metadata: attachment.metadata
    }
  end

  def samplesheet_fastq_files(property, pattern)
    direction = fastq_direction(property)
    singles = filter_files_by_pattern(sorted_files[:singles] || [], pattern || /^\S+\.f(ast)?q(\.gz)?$/)
    files = sorted_files.fetch(direction, [])

    files.concat(singles) if (direction == :pe_forward && property['pe_only'].blank?) || direction == :none
    files.sort_by! { |file| file[:created_at] }.reverse
  end

  def most_recent_fastq_files # rubocop:disable Metrics/MethodLength
    metadata_node = create_query_node('direction')
    associated_attachment_node = create_query_node('associated_attachment_id')

    # prioritize paired attachment before returning single attachment
    forward_file = attachments.where(
      metadata_node.eq('forward'),
      associated_attachment_node.not_eq(nil)
    ).order(created_at: :desc, id: :desc).first

    if forward_file
      { 'fastq_1' => file_attributes(forward_file),
        'fastq_2' => file_attributes(forward_file.associated_attachment) }
    else
      node = create_query_node('format')
      single_file = attachments.where(node.eq('fastq')).order(created_at: :desc, id: :desc).first
      if single_file
        { 'fastq_1' => file_attributes(single_file), 'fastq_2' => {} }
      else
        { 'fastq_1' => {}, 'fastq_2' => {} }
      end
    end
  end

  def most_recent_other_file(autopopulate, pattern)
    return {} unless autopopulate

    most_recent_file = nil
    # find file that fits regex
    if pattern
      most_recent_file = attachments
                         .joins(:file_blob)
                         .where(ActiveStorage::Blob.arel_table[:filename].matches_regexp(pattern))
                         .order(created_at: :desc, id: :desc)
                         .first
    # find file that is not fastq
    else
      node = create_query_node('format')
      most_recent_file = attachments.where(node.not_eq('fastq')).order(created_at: :desc, id: :desc).first
    end

    return {} unless most_recent_file

    file_attributes(most_recent_file)
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

  def file_attributes(file)
    {
      filename: file.file.filename.to_s,
      global_id: file.to_global_id,
      id: file.id
    }
  end

  def create_query_node(key)
    Arel::Nodes::InfixOperation.new('->>', Attachment.arel_table[:metadata],
                                    Arel::Nodes::Quoted.new(key))
  end
end
