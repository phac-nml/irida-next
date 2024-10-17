# frozen_string_literal: true

# Common Attachment Actions
module AttachmentActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { current_page }
    before_action proc { set_namespace }
    before_action proc { set_authorization_object }
    before_action :new_destroy_params, only: %i[new_destroy]
    before_action :attachment, only: %i[destroy]
  end

  def index
    authorize! @authorize_object, to: :view_attachments?

    @render_individual_attachments = filter_requested?
    all_attachments = load_attachments
    @has_attachments = all_attachments.count.positive?
    @search_params = params[:q]
    @q = all_attachments.ransack(@search_params)
    set_default_sort
    @pagy, @attachments = pagy_with_metadata_sort(@q.result)
  end

  def new
    authorize! @authorize_object, to: :create_attachment?

    render turbo_stream: turbo_stream.update('attachment_modal',
                                             partial: 'new_attachment_modal',
                                             locals: {
                                               open: true,
                                               attachment: Attachment.new(attachable: @namespace),
                                               namespace: @namespace
                                             }), status: :ok
  end

  def create
    @attachments = ::Attachments::CreateService.new(current_user, @namespace, attachment_params).execute

    status = if !@attachments.count.positive?
               :unprocessable_entity
             elsif @attachments.count(&:persisted?) == @attachments.count
               :ok
             else
               :multi_status
             end

    respond_to do |format|
      format.turbo_stream do
        render status:, locals: { attachment: Attachment.new(attachable: @namespace),
                                  attachments: @attachments }
      end
    end
  end

  def new_destroy
    authorize! @authorize_object, to: :destroy_attachment?
    render turbo_stream: turbo_stream.update('attachment_modal',
                                             partial: 'delete_attachment_modal',
                                             locals: {
                                               open: true,
                                               attachment: @attachment,
                                               namespace: @namespace
                                             }), status: :ok
  end

  def destroy # rubocop:disable Metrics/MethodLength
    @destroyed_attachments = ::Attachments::DestroyService.new(@namespace, @attachment, current_user).execute
    respond_to do |format|
      if @destroyed_attachments.count.positive?
        status = destroy_status(@attachment, @destroyed_attachments.length)
        format.turbo_stream do
          render status:, locals: { destroyed_attachments: @destroyed_attachments }
        end
      else
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals: { message: t('.error',
                                      filename: @attachment.file.filename,
                                      errors: @attachment.errors.full_messages.first),
                           destroyed_attachments: nil }
        end
      end
    end
  end

  private

  def filter_requested?
    params.dig(:q, :puid_or_file_blob_filename_cont).present?
  end

  def load_attachments
    if @render_individual_attachments
      @namespace.attachments.all
    else
      @namespace.attachments
                .where.not(Attachment.arel_table[:metadata].contains({ direction: 'reverse' }))
    end
  end

  def new_destroy_params
    @attachment = Attachment.find_by(id: params[:attachment_id])
  end

  def attachment
    @attachment = Attachment.find_by(id: params[:id])
  end

  def destroy_status(attachment, count)
    return count == 2 ? :ok : :multi_status if attachment.associated_attachment

    count == 1 ? :ok : :unprocessable_entity
  end

  def layout_fixed
    super
    return unless action_name == 'index'

    @fixed = false
  end

  def set_default_sort
    @q.sorts = 'updated_at desc' if @q.sorts.empty?
  end

  def attachment_params
    params.require(:attachment).permit(:attachable_id, :attachable_type, files: [])
  end
end
