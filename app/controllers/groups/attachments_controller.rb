# frozen_string_literal: true

module Groups
  # Controller actions for Group Attachments
  class AttachmentsController < Groups::ApplicationController
    include Metadata
    before_action :group, :current_page

    def index
      authorize! @group, to: :view_attachments?

      @q = @group.attachments.ransack(params[:q])
      set_default_sort
      @pagy, @attachments = pagy_with_metadata_sort(@q.result)
    end

    def new
      authorize! @group, to: :create_attachment?

      render turbo_stream: turbo_stream.update('attachment_modal',
                                               partial: 'new_attachment_modal',
                                               locals: {
                                                 open: true,
                                                 attachment: Attachment.new(attachable: @group)
                                               }), status: :ok
    end

    def create
      @attachments = ::Attachments::CreateService.new(current_user, @group, attachment_params).execute

      status = if !@attachments.count.positive?
                 :unprocessable_entity
               elsif @attachments.count(&:persisted?) == @attachments.count
                 :ok
               else
                 :multi_status
               end

      respond_to do |format|
        format.turbo_stream do
          render status:, locals: { attachment: Attachment.new(attachable: @group),
                                    attachments: @attachments }
        end
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def current_page
      @current_page = t(:'groups.sidebar.files')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: t(:'groups.sidebar.files'),
          path: group_attachments_path(@group)
        }]
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
end
