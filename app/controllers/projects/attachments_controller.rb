# frozen_string_literal: true

module Projects
  # Controller actions for Project Attachments
  class AttachmentsController < Projects::ApplicationController
    include Metadata
    before_action :current_page

    def index
      @q = @project.namespace.attachments.ransack(params[:q])
      set_default_sort
      @pagy, @attachments = pagy_with_metadata_sort(@q.result)
    end

    def new
      authorize! @project, to: :create_attachment?

      render turbo_stream: turbo_stream.update('attachment_modal',
                                               partial: 'new_attachment_modal',
                                               locals: {
                                                 open: true,
                                                 attachment: Attachment.new(attachable: @project.namespace)
                                               }), status: :ok
    end

    def create
      authorize! @project, to: :update_sample?

      @attachments = ::Attachments::CreateService.new(current_user, @project.namespace, attachment_params).execute

      status = if !@attachments.count.positive?
                 :unprocessable_entity
               elsif @attachments.count(&:persisted?) == @attachments.count
                 :ok
               else
                 :multi_status
               end

      respond_to do |format|
        format.turbo_stream do
          render status:, locals: { attachment: Attachment.new(attachable: @project.namespace),
                                    attachments: @attachments }
        end
      end
    end

    def search
      redirect_to namespace_project_attachments_path(@project.parent, @project, limit: params[:limit])
    end

    private

    def current_page
      @current_page = t(:'projects.sidebar.files')
    end

    def context_crumbs
      super
      @context_crumbs +=
        [{
          name: t(:'projects.sidebar.files'),
          path: namespace_project_attachments_path(@project.parent, @project)
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
