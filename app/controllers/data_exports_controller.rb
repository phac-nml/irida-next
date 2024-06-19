# frozen_string_literal: true

# Controller actions for Data Exports
class DataExportsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include BreadcrumbNavigation
  include SampleActions

  before_action :data_export, only: %i[destroy show]
  before_action :data_exports, only: %i[index destroy]
  before_action :current_page
  before_action :set_default_tab, only: :show

  TABS = %w[summary preview].freeze

  def index; end

  def show
    authorize! @data_export, to: :read_export?

    return if @data_export.manifest.empty?

    @manifest = JSON.parse(@data_export.manifest)
  end

  def new
    if params[:export_type] == 'sample'
      render turbo_stream: turbo_stream.update('samples_dialog',
                                               partial: 'new_sample_export_dialog',
                                               locals: {
                                                 open: true
                                               }), status: :ok
    else
      render turbo_stream: turbo_stream.update('export_dialog',
                                               partial: 'new_analysis_export_dialog',
                                               locals: {
                                                 open: true,
                                                 workflow_execution_id: params[:workflow_execution_id]
                                               }), status: :ok
    end
  end

  def create
    @data_export = DataExports::CreateService.new(current_user, data_export_params).execute

    if @data_export.valid?
      flash[:success] = t('.success', name: @data_export.name || @data_export.id)

      redirect_to data_export_path(@data_export, format: :html)
    else
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals: { type: 'alert', message: @data_export.errors.full_messages.first }
        end
      end
    end
  end

  def redirect_from
    if params['puid'].include?('INXT_SAM')
      sample = Sample.find_by(puid: params['puid'])
      project = Project.find(sample.project_id)
      namespace = project.namespace.parent
      redirect_to namespace_project_sample_path(namespace, project, sample, tab: 'files')
    else
      project = Namespace.find_by(puid: params['puid']).project
      redirect_to namespace_project_path(project.parent, project)
    end
  end

  def destroy # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    DataExports::DestroyService.new(@data_export, current_user).execute
    # Destroyed from data export show view
    if !@data_export.persisted? && params[:redirect]
      flash[:success] = t('.success', name: @data_export.name || @data_export.id)
      redirect_to data_exports_path
    # Destroyed from data exports listing index view
    else
      respond_to do |format|
        format.turbo_stream do
          if @data_export.persisted?
            render status: :unprocessable_entity, locals: { type: 'alert', message: t('.error') }
          else
            render status: :ok,
                   locals: { type: 'success', message: t('.success', name: @data_export.name || @data_export.id) }
          end
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

  def data_exports
    @data_exports = DataExport.where(user: current_user)
  end

  def current_page
    @current_page = 'data exports'
  end

  def set_default_tab
    @tab = 'summary'

    return if params[:tab].nil? || (params[:tab] == 'preview' && @data_export.manifest.empty?)

    redirect_to @data_export, tab: 'summary' unless TABS.include?(params[:tab])

    @tab = params[:tab]
  end

  def context_crumbs
    @context_crumbs =
      [{
        name: I18n.t('data_exports.index.title'),
        path: data_exports_path
      }]
    return unless action_name == 'show'

    @context_crumbs +=
      [{
        name: @data_export.id,
        path: data_export_path(@data_export)
      }]
  end
end
