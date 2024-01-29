# frozen_string_literal: true

# Common history actions
module HistoryActions
  extend ActiveSupport::Concern

  included do
    before_action proc { set_model }
    before_action proc { set_authorization_object }
  end

  def index
    authorize! @authorize_object, to: :view_history?

    respond_to do |format|
      format.html
      format.turbo_stream do
        @log_data = @model.log_data_without_changes
      end
    end
  end

  def new
    authorize! @authorize_object, to: :view_history?

    @log_data = @model.log_data_with_changes(params[:version])
    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end
end
