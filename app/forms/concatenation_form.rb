# frozen_string_literal: true

# form object for concatenating attachments
class ConcatenationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :attachable_id, :string
  attribute :attachable_type, :string
  attribute :basename, :string
  attribute :delete_originals, :boolean, default: false
  attribute :attachment_ids, array: true, default: -> { [] }

  before_validation :compact_attachment_ids

  validates :basename, presence: true, format: { with: /\A[a-zA-Z0-9_\-.]+\Z/, allow_blank: true }
  validates :attachment_ids, presence: true, length: { minimum: 2 }

  validate :attachments_belong_to_attachable, if: -> { attachment_ids.any? }
  validate :attachments_file_formats, if: -> { attachment_ids.any? }
  validate :attachments_file_types, if: -> { attachment_ids.any? }

  def initialize(attributes = {})
    super
    self.attachment_ids = attachment_ids.values unless attachment_ids.is_a?(Array)
  end

  def attachable
    return @attachable if defined?(@attachable)

    @attachable = attachable_type.constantize.find_by(id: attachable_id)
  end

  def flattened_attachment_ids
    return @flattened_attachment_ids if defined?(@flattened_attachment_ids)

    @flattened_attachment_ids = if attachment_ids.all? { |i| i.is_a?(Integer) || i.is_a?(String) }
                                  attachment_ids
                                else
                                  attachment_ids.flatten
                                end
  end

  def attachments
    return @attachments if defined?(@attachments)

    @attachments = attachable.attachments.where(id: flattened_attachment_ids).order(:puid)
  end

  def paired_end?
    return @paired_end if defined?(@paired_end)

    @paired_end = attachment_ids.length != flattened_attachment_ids.length
  end

  private

  def compact_attachment_ids
    self.attachment_ids = attachment_ids.compact_blank if attachment_ids.is_a?(Array)
  end

  def attachments_belong_to_attachable
    return if Attachment.where(id: flattened_attachment_ids,
                               attachable_id: attachable_id,
                               attachable_type: attachable_type).count == flattened_attachment_ids.length

    errors.add(:attachment_ids, :mismatching_attachable,
               attachable_type: I18n.t("activerecord.models.#{attachable_type.underscore}.one"))
  end

  def attachments_file_formats
    return if Attachment.where(id: flattened_attachment_ids)
                        .group(Attachment.metadata_arel_node('format'),
                               Attachment.metadata_arel_node('compression')).count.length == 1

    errors.add(:attachment_ids, :mismatching_file_formats)
  end

  def attachments_file_types
    attachment_file_types = Attachment.where(id: flattened_attachment_ids)
                                      .group(Attachment.metadata_arel_node('type'))
                                      .count.keys
    if paired_end?
      return if attachment_file_types.all? { |t| %w[illumina_pe pe].include?(t) }
    elsif attachment_file_types.length == 1 && attachment_file_types.none? { |t| %w[illumina_pe pe].include?(t) }
      return
    end

    errors.add(:attachment_ids, :mismatching_file_types)
  end
end
