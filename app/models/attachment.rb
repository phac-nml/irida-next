# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord
  include HasPuid
  include MetadataSortable

  FORMAT_REGEX = {
    'fasta' => /^\S+\.fn?a(sta)?(\.gz)?$/,
    'fastq' => /^\S+\.f(ast)?q(\.gz)?$/,
    'text' => /^\S+\.(txt|rtf)?(\.gz)?$/,
    'csv' => /^\S+\.(csv)?(\.gz)?$/,
    'tsv' => /^\S+\.(tsv)?(\.gz)?$/,
    'spreadsheet' => /^\S+\.(xls|xlsx)?$/,
    'json' => /^\S+\.(json)?(\.gz)?$/,
    'genbank' => /^\S+\.(gbk|gbf|genbank)?(\.gz)?$/,
    'image' => /^\S+\.(png|jpg|jpeg|gif|bmp|tiff|svg|webp)$/,
    'unknown' => nil
  }.freeze

  PREVIEWABLE_TYPES = {
    'image' => :image,
    'text' => :text,
    'fasta' => :text,
    'fastq' => :text,
    'genbank' => :text,
    'json' => :json,
    'csv' => :csv,
    'tsv' => :tsv,
    'spreadsheet' => :excel
  }.freeze

  COPYABLE_TYPES = %w[text json csv tsv fasta fastq genbank].freeze

  has_logidze
  acts_as_paranoid
  broadcasts_refreshes

  belongs_to :attachable, touch: :attachments_updated_at, polymorphic: true

  has_one_attached :file

  validates :file, attached: true

  validates_with AttachmentChecksumValidator

  after_initialize :assign_metadata

  delegate :filename, to: :file

  delegate :byte_size, to: :file

  ransack_alias :filename, :file_blob_filename
  ransack_alias :byte_size, :file_blob_byte_size

  def self.model_prefix
    'ATT'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[puid metadata created_at updated_at] + _ransack_aliases.keys
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[file_blob]
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

  def previewable?
    PREVIEWABLE_TYPES.key?(metadata['format'])
  end

  def copyable?
    COPYABLE_TYPES.include?(metadata['format'])
  end

  private

  def assign_metadata # rubocop:disable Metrics/AbcSize
    return if metadata.key? 'format'

    found_format = FORMAT_REGEX.find { |_key, value| filename.to_s =~ value }

    if found_format.nil?
      metadata['format'] = 'unknown'
    else
      metadata['format'] = found_format[0]
      metadata['type'] = 'assembly' if metadata['format'] == 'fasta'
    end

    metadata['compression'] = filename.to_s.match?(/^\S+(.gz)+$/) ? 'gzip' : 'none'
  end
end
