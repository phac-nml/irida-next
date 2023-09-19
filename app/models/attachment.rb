# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :attachable, polymorphic: true

  has_one_attached :file

  validates :file, attached: true

  validates_with AttachmentChecksumValidator

  before_create :assign_metadata

  # override destroy so that on soft delete we don't delete the ActiveStorage::Attachment
  def destroy
    update(deleted_at: Time.current)
  end

  private
  def assign_metadata
    case self.file.filename.to_s
    # Assigns fasta to metadata format for following file types: .fasta, .fasta.gz, .fna, .fna.gz, .fa, .fa.gz
    when /^\S+\.fn?a(sta)?(\.gz)?$/
      self.metadata[:format] = "fasta"
    # Assigns fastq to metadata format for following file types: .fastq, .fastq.gz, .fq, .fq.gz
    when /^\S+\.f(ast)?q(\.gz)?$/
      self.metadata[:format] = "fastq"
    # Else assigns unknown to metadata format
    else
      self.metadata[:format] = "unknown"
    end
  end
end
