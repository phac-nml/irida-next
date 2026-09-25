# frozen_string_literal: true

# Common Attachment Actions
module AttachmentActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  include AttachmentSearchable

  included do
    before_action proc { current_page }
    before_action proc { set_namespace }
    before_action proc { set_authorization_object }
    before_action :new_destroy_params, only: %i[new_destroy]
    before_action :attachment, only: %i[destroy]
    before_action proc { view_authorizations }, only: %i[index]
  end

  def index
    authorize! @authorize_object, to: :view_attachments?

    @render_individual_attachments = filter_requested?
    all_attachments = load_attachments
    @query = attachments_query(@namespace)
    @has_attachments = all_attachments.any?
    @search_params = attachment_search_params

    @pagy, @attachments = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
    @results_message = attachments_results_message

    setup_ransack_for_attachments_form(all_attachments)
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

    status = if @attachments.none?
               :unprocessable_content
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
      if @destroyed_attachments.any?
        status = destroy_status(@attachment, @destroyed_attachments.length)
        format.turbo_stream do
          render status:, locals: { destroyed_attachments: @destroyed_attachments }
        end
      else
        format.turbo_stream do
          render status: :unprocessable_content,
                 locals: { message: t('.error',
                                      filename: @attachment.file.filename,
                                      errors: error_message(@attachment)),
                           destroyed_attachments: nil }
        end
      end
    end
  end

  private

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

    count == 1 ? :ok : :unprocessable_content
  end

  def layout_fixed
    super
    return unless action_name == 'index'

    @fixed = false
  end

  def attachment_params
    params.expect(attachment: [:attachable_id, :attachable_type, { files: [] }])
  end
end
