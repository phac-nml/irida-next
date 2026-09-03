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

    # @render_individual_attachments = filter_requested?
    # all_attachments = load_attachments
    # @has_attachments = all_attachments.any?
    # @q = all_attachments.ransack(params[:q])
    # set_default_sort
    # @pagy, @attachments = pagy_with_metadata_sort(@q.result)
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

  def filter_requested?
    params.dig(:q, :puid_or_file_blob_filename_cont).present?
  end

  def attachments_query(attachable)
    Attachment::Query.new(attachment_search_params.merge(request:, attachables: [attachable]))
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

  def setup_ransack_for_attachments_form(all_attachments)
    # Create Ransack object from request params for UI component compatibility
    @q = all_attachments.ransack(params[:q])
    # Sync search values from custom Query to Ransack for accurate form display
    @q.puid_or_file_blob_filename_cont = @query.puid_or_file_blob_filename_cont
    # Set default sort order if none provided
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end

  def attachment_search_params
    search_params = {}
    search_params[:puid_or_file_blob_filename_cont] = params.dig(:q, :puid_or_file_blob_filename_cont)
    search_params[:sort] = params.dig(:q, :s)

    groups_attributes = attachment_advanced_search_groups_attributes
    search_params[:groups_attributes] = groups_attributes if groups_attributes.present?

    search_params.compact
  end

  def attachment_advanced_search_groups_attributes
    groups_attributes = params.dig(:q, :groups_attributes)
    return if groups_attributes.blank?

    # Advanced search groups use dynamic nested keys; preserve all keys.
    groups_attributes.respond_to?(:to_unsafe_h) ? groups_attributes.to_unsafe_h : groups_attributes
  end

  def attachments_results_message
    return advanced_search_results_message if @query.advanced_query?

    return if @query.puid_or_file_blob_filename_cont.blank?

    quick_search_results_message(@query.puid_or_file_blob_filename_cont)
  end

  def advanced_search_results_message
    if @pagy&.count&.zero?
      I18n.t(:'components.search.advanced.results_message.zero')
    elsif @pagy&.count == 1 # rubocop:disable Style/CollectionQuerying
      I18n.t(:'components.search.advanced.results_message.singular')
    else
      I18n.t(:'components.search.advanced.results_message.plural', total_count: @pagy&.count)
    end
  end

  def quick_search_results_message(search_term)
    if @pagy&.count&.zero?
      I18n.t(:'components.search.results_message.zero', search_term: search_term)
    elsif @pagy&.count == 1 # rubocop:disable Style/CollectionQuerying
      I18n.t(:'components.search.results_message.singular', search_term: search_term)
    else
      I18n.t(:'components.search.results_message.plural', total_count: @pagy&.count,
                                                          search_term: search_term)
    end
  end
end
