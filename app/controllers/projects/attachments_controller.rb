# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class AttachmentsController < Projects::ApplicationController
    before_action :current_page

    def index
      @q = @project.namespace.attachments.ransack(params[:q])
      set_default_sort
      @pagy, @attachments = pagy(@q.result)
    end

    def new
    end

    def create
    end

    private

    def current_page
      @current_page = t(:'projects.sidebar.files')
    end

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end
  end
end
