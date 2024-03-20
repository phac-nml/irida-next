# frozen_string_literal: true

# Controller actions for Data Exports
class DataExportsController < ApplicationController
  before_action :data_export, only: %i[download destroy]
  before_action :current_page

  def index
    @data_exports = DataExport.where(user: current_user)
  end

  def new
    render turbo_stream: turbo_stream.update('export_modal',
                                             partial: 'new_export_modal',
                                             locals: {
                                               open: true,
                                               samples: params[:samples]
                                             }), status: :ok
  end

  def download
    authorize! @data_export, to: :download?

    send_data @data_export.file.download, filename: @data_export.file.filename.to_s
  end

  def create
    @data_export = DataExports::CreateService.new(current_user, data_export_params).execute

    if @data_export.valid?
      flash[:success] = t('.success')
      redirect_to data_exports_path
    else
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { type: 'alert', message: t('.error') }
        end
      end
    end
  end

  def destroy
    DataExports::DestroyService.new(@data_export, current_user).execute
    respond_to do |format|
      format.turbo_stream do
        if @data_export.persisted?
          render status: :unprocessable_entity, locals: { type: 'alert', message: t('.error') }
        else
          render status: :ok, locals: { type: 'success', message: t('.success') }
        end
      end
    end
  end

  private

  def data_export_params
    params.require(:data_export).permit(:name, :export_type, :email_notification, export_parameters: { ids: [] })
  end

  def data_export
    @data_export = DataExport.find(params[:id])
  end

  def current_page
    @current_page = 'data exports'
  end
end
