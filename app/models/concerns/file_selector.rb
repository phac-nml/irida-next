# frozen_string_literal: true

# Concern with for retrieving and organizing files within the nextflow samplesheet file selector
module FileSelector # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  ### TODO START: Remove functions between this block when feature flag deferred_samplesheet is retired ###
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

  # separate function from samplesheet_fastq_files since this function would prefer selection of latest paired_end
  # attachments, where as samplesheet_fastq_files will return the overall latest attachment (ie: possibly a single)
  def most_recent_fastq_file(property, pattern)
    direction = fastq_direction(property)

    if sorted_files[direction].present?
      sorted_files[direction].last
    elsif %i[pe_forward none].include?(direction)
      last_single = filter_files_by_pattern(sorted_files[:singles] || [], pattern || /^\S+\.f(ast)?q(\.gz)?$/).last
      last_single.nil? ? {} : last_single
    else
      {}
    end
  end

  def most_recent_other_file(autopopulate, pattern)
    return {} unless autopopulate

    if Flipper.enabled?(:deferred_samplesheet)
      most_recent_other_file_with_feature_flag(pattern)
    else
      most_recent_other_file_without_feature_flag(pattern)
    end
  end

  def most_recent_other_file_without_feature_flag(pattern)
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
  ### TODO END ###

  def file_selector_fastq_files(property, pe_only)
    fastq_files = query_fastq_files(property == 'fastq_1' ? 'forward' : 'reverse', property == 'fastq_1' && !pe_only)
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

  def most_recent_fastq_files(pe_only)
    attributes = { 'fastq_1' => {}, 'fastq_2' => {} }

    # prioritize paired attachment before returning single attachment
    forward_file = query_fastq_files('forward', false).first

    if forward_file
      attributes['fastq_1'] = file_attributes(forward_file, 'samplesheet')
      attributes['fastq_2'] = file_attributes(forward_file.associated_attachment, 'samplesheet')
    elsif !forward_file && !pe_only
      single_file = query_single_fastq_files.order(created_at: :desc, id: :desc).first
      attributes['fastq_1'] = file_attributes(single_file, 'samplesheet') if single_file
    end
    attributes
  end

  # TODO: rename to "most_recent_other_file" when deferred_samplesheet is retired
  def most_recent_other_file_with_feature_flag(pattern)
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

  # TODO: Remove fastq_direction when deferred_samplesheet is retired
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
