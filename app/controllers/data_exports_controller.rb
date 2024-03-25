# frozen_string_literal: true

# Controller actions for Data Exports
class DataExportsController < ApplicationController
  before_action :data_export, only: %i[download destroy show remove]
  before_action :data_exports, only: %i[index destroy]
  before_action :current_page

  def index; end

  def show
    authorize! @data_export, to: :read_export?
    @tab = params[:tab]
    return unless @data_export.status == 'ready'

    @manifest = JSON.parse(@data_export.manifest)
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

  def redirect_from
    if params['puid'].include?('INXT_SAM')
      sample = Sample.find_by(puid: params['puid'])
      project = Project.find(sample.project_id)
      namespace = project.namespace.parent
      redirect_to namespace_project_sample_path(namespace, project, sample)
    else
      project = Project.find_by(puid: params['puid'])
      namespace = project.namespace.parent
      redirect_to namespace_project_path(namespace, project)
    end
  end

  # Delete from data_exports listing page
  def destroy
    DataExports::DestroyService.new(@data_export, current_user).execute
    respond_to do |format|
      format.turbo_stream do
        if @data_export.persisted?
          render status: :unprocessable_entity, locals: { type: 'alert', message: t('.error') }
        else
          render status: :ok,
                 locals: { type: 'success',
                           message: t('.success', name: @data_export.name || @data_export.id) }
        end
      end
    end
  end

  # Delete from individual data_export page
  def remove
    DataExports::DestroyService.new(@data_export, current_user).execute
    if @data_export.persisted?
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, locals: { type: 'alert', message: t('.error') }
        end
      end
    else
      flash[:success] = t('.success', name: @data_export.name || @data_export.id)
      redirect_to data_exports_path
    end
  end

  private

  def data_export_params
    params.require(:data_export).permit(:name, :export_type, :email_notification, export_parameters: { ids: [] })
  end

  def data_export
    @data_export = DataExport.find(params[:id])
  end

  def data_exports
    @data_exports = DataExport.where(user: current_user)
  end

  def current_page
    @current_page = 'data exports'
  end
end
