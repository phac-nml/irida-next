# frozen_string_literal: true

# entity class for Attachment
class Attachment < ApplicationRecord # rubocop:disable Metrics/ClassLength
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

  FASTQ_PAIRING_FILENAME_REGEX = {
    'illumina_pe' => /^(?<sample_name>.+_[^_]+(?:_L[0-9]{3})?)_R(?<region>[1-2])_(?<set>[0-9]{3})\.(?<suffix>.+)$/,
    'pe' => /^(?<sample_name>.+_)(?<region>R?[1-2]|[FfRr])\.(?<suffix>.+)$/
  }.freeze

  FASTQ_PAIRING_TYPES = %w[illumina_pe pe].freeze

  FASTQ_PE_REGION_PAIRING = {
    '1' => { direction: 'forward', pair_key_suffix: '1-2' },
    '2' => { direction: 'reverse', pair_key_suffix: '1-2' },
    'R1' => { direction: 'forward', pair_key_suffix: 'R1-R2' },
    'R2' => { direction: 'reverse', pair_key_suffix: 'R1-R2' },
    'F' => { direction: 'forward', pair_key_suffix: 'F-R' },
    'R' => { direction: 'reverse', pair_key_suffix: 'F-R' },
    'f' => { direction: 'forward', pair_key_suffix: 'f-r' },
    'r' => { direction: 'reverse', pair_key_suffix: 'f-r' }
  }.freeze

  FastqPairingInfo = Data.define(:type, :direction, :pair_key)

  PREVIEWABLE_TYPES = {
    'image' => :image,
    'text' => :text,
    'fasta' => :text,
    'fastq' => :text,
    'genbank' => :text,
    'json' => :json,
    'csv' => :csv,
    'tsv' => :tsv,
    'spreadsheet' => :spreadsheet
  }.freeze

  COPYABLE_TYPES = %w[text json csv tsv fasta fastq genbank].freeze

  has_logidze
  acts_as_paranoid
  broadcasts_refreshes

  belongs_to :attachable, touch: :attachments_updated_at, polymorphic: true

  has_one_attached :file

  scope :matching_filename, lambda { |pattern|
    joins(:file_blob).where(ActiveStorage::Blob.arel_table[:filename].matches_regexp(pattern))
  }

  scope :with_direction, lambda { |direction, include_nils: false|
    where(
      if include_nils
        Attachment.metadata_arel_node('direction').eq(nil).or(Attachment.metadata_arel_node('direction').eq(direction))
      else
        Attachment.metadata_arel_node('direction').eq(direction)
      end
    )
  }

  scope :with_associated_attachment, lambda {
    where(Attachment.metadata_arel_node('associated_attachment_id').not_eq(nil))
  }

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  scope :prefer_associated_attachment, lambda {
    order(Arel::Nodes::Case.new.when(Attachment.metadata_arel_node('associated_attachment_id').not_eq(nil)).then(0).else(1))
  }

  validates :file, attached: true

  validates_with AttachmentChecksumValidator, on: :create

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

  def self.icon
    :file_text
  end

  def self.fastq_pairing_filename_patterns
    FASTQ_PAIRING_FILENAME_REGEX.transform_values(&:source)
  end

  def self.fastq_illumina_pe_pairing_info(filename)
    match = FASTQ_PAIRING_FILENAME_REGEX['illumina_pe'].match(filename.to_s)
    return unless match

    FastqPairingInfo.new(
      type: 'illumina_pe',
      direction: match[:region] == '1' ? 'forward' : 'reverse',
      pair_key: "#{match[:sample_name]}_#{match[:set]}_#{match[:suffix]}"
    )
  end

  def self.fastq_pe_pairing_info(filename)
    match = FASTQ_PAIRING_FILENAME_REGEX['pe'].match(filename.to_s)
    return unless match

    config = FASTQ_PE_REGION_PAIRING[match[:region]]
    return unless config

    FastqPairingInfo.new(
      type: 'pe',
      direction: config[:direction],
      pair_key: "#{match[:sample_name]}_#{config[:pair_key_suffix]}_#{match[:suffix]}"
    )
  end

  def self.fastq_pairing_info(filename, type:)
    case type
    when 'illumina_pe'
      fastq_illumina_pe_pairing_info(filename)
    when 'pe'
      fastq_pe_pairing_info(filename)
    end
  end

  def self.metadata_arel_node(key)
    Arel::Nodes::InfixOperation.new('->>', arel_table[:metadata], Arel::Nodes::Quoted.new(key))
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
    PREVIEWABLE_TYPES.key?(metadata['format']) && metadata['compression'] == 'none'
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
