# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord
  self.implicit_order_column = 'created_at'
  has_logidze
  acts_as_paranoid

  belongs_to :attachable, polymorphic: true

  has_one_attached :file

  validates :file, attached: true

  validates_with AttachmentChecksumValidator

  before_create :assign_metadata

  delegate :filename, to: :file

  delegate :byte_size, to: :file

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
    attachable.attachments.find_by(id: metadata['associated_attachment_id'])
  end

  private

  def assign_metadata
    case filename.to_s
    # Assigns fasta to metadata format and assembly to type for following file types:
    # .fasta, .fasta.gz, .fna, .fna.gz, .fa, .fa.gz
    when /^\S+\.fn?a(sta)?(\.gz)?$/
      metadata['format'] = 'fasta'
      metadata['type'] = 'assembly'
    # Assigns fastq to metadata format for following file types: .fastq, .fastq.gz, .fq, .fq.gz
    when /^\S+\.f(ast)?q(\.gz)?$/
      metadata['format'] = 'fastq'
    # Else assigns unknown to metadata format
    else
      metadata['format'] = 'unknown'
    end
    metadata['compression'] = filename.to_s.match?(/^\S+(.gz)+$/) ? 'gzip' : 'none'
  end
end
