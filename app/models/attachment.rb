# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord
  has_logidze
  acts_as_paranoid

  include HasPuid

  belongs_to :attachable, touch: :attachments_updated_at, polymorphic: true

  has_one_attached :file

  validates :file, attached: true

  validates_with AttachmentChecksumValidator

  after_initialize :assign_metadata

  delegate :filename, to: :file

  delegate :byte_size, to: :file

  def self.model_prefix
    'ATT'
  end

  # override destroy so that on soft delete we don't delete the ActiveStorage::Attachment
  def destroy
    update(deleted_at: Time.current)
  end

  def fastq?
    metadata['format'] == 'fastq'
  end

  def fasta?
    metadata['format'] == 'fasta'
  end

  def associated_attachment
    Attachment.find_by(attachable:, id: metadata['associated_attachment_id'])
  end

  private

  def assign_metadata # rubocop:disable Metrics/AbcSize
    return if metadata.key? 'format'

    case filename.to_s
    # Assigns fasta to metadata format and assembly to type for following file types:
    # .fasta, .fasta.gz, .fna, .fna.gz, .fa, .fa.gz
    when /^\S+\.fn?a(sta)?(\.gz)?$/
      metadata['format'] = 'fasta'
      metadata['type'] = 'assembly'
    # Assigns fastq to metadata format for following file types: .fastq, .fastq.gz, .fq, .fq.gz
    when /^\S+\.f(ast)?q(\.gz)?$/
      metadata['format'] = 'fastq'
    # Assigns text to metadata format for following file types: .txt, .csv, .tsv
    when /^\S+\.(txt|csv|tsv)?$/
      metadata['format'] = 'text'
    # Assigns spreadsheet to metadata format for following file types: .xls, .xlsx
    when /^\S+\.(xls|xlsx)?$/
      metadata['format'] = 'spreadsheet'
    # Else assigns unknown to metadata format
    else
      metadata['format'] = 'unknown'
    end
    metadata['compression'] = filename.to_s.match?(/^\S+(.gz)+$/) ? 'gzip' : 'none'
  end
end
