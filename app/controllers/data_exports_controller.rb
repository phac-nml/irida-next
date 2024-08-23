# frozen_string_literal: true

# Controller actions for Data Exports
class DataExportsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include BreadcrumbNavigation
  include ListActions

  before_action :data_export, only: %i[destroy show]
  before_action :data_exports, only: %i[index destroy]
  before_action :namespace, only: :new
  before_action :current_page
  before_action :set_default_tab, only: :show

  TABS = %w[summary preview].freeze

  def index; end

  def show
    authorize! @data_export, to: :read_export?

    return if @data_export.manifest.empty? || @data_export.export_type == 'linelist'

    @manifest = JSON.parse(@data_export.manifest)
  end

  def new
    # Handles analysis exports created from show page
    if params[:export_type] == 'analysis' && params[:single_workflow]
      render turbo_stream: turbo_stream.update('export_dialog',
                                               partial: 'new_single_analysis_export_dialog',
                                               locals: new_locals), status: :ok
    else
      render turbo_stream: turbo_stream.update(params[:export_type] == 'analysis' ? 'export_dialog' : 'samples_dialog',
                                               partial: "new_#{params[:export_type]}_export_dialog",
                                               locals: new_locals), status: :ok
    end
  end

  def create
    @data_export = DataExports::CreateService.new(current_user, data_export_params).execute

    if @data_export.errors.any?
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity,
                 locals: { type: 'alert', message: @data_export.errors.full_messages.first }
        end
      end
    else
      flash[:success] = t('.success', name: @data_export.name || @data_export.id)

      redirect_to data_export_path(@data_export, format: :html)
    end
  end

  def redirect_from
    if params['id'].include?('INXT_SAM')
      redirect_to_sample
    elsif params['id'].include?('INXT_PRJ')
      redirect_to_project
    else
      redirect_to_workflow_execution
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
    params.require(:data_export).permit(:name, :export_type, :email_notification,
                                        export_parameters: [:linelist_format, :namespace_id, :analysis_type,
                                                            { ids: [], metadata_fields: [], attachment_formats: [] }])
  end

  def data_export
    @data_export = DataExport.find(params[:id])
  end

  def data_exports
    @data_exports = DataExport.where(user: current_user)
  end

  def namespace
    return unless params[:export_type] == 'linelist'

    @namespace = Namespace.find(params[:namespace_id])
  end

  def current_page
    @current_page = t(:'general.default_sidebar.data_exports')
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

  def new_locals
    case params[:export_type]
    when 'analysis'
      analysis_locals
    when 'sample'
      { open: true, namespace_id: params[:namespace_id], formats: Attachment::FORMAT_REGEX.keys.sort }
    when 'linelist'
      { open: true, namespace_id: params[:namespace_id] }
    end
  end

  def analysis_locals
    local = { open: true,
              analysis_type: params['analysis_type'],
              namespace_id: params['analysis_type'] == 'project' ? params[:namespace_id] : nil }
    local[:workflow_execution] = WorkflowExecution.find(params[:workflow_execution_id]) if params[:single_workflow]
    local
  end

  def redirect_to_sample
    sample = Sample.find_by(puid: params['id'])
    project = Project.find(sample.project_id)
    namespace = project.namespace.parent
    redirect_to namespace_project_sample_path(namespace, project, sample, tab: 'files')
  end

  def redirect_to_project
    project = Namespace.find_by(puid: params['id']).project
    redirect_to namespace_project_samples_path(project.parent, project)
  end

  def redirect_to_workflow_execution
    workflow_execution = WorkflowExecution.find_by(id: params['id'])
    submitter = workflow_execution.submitter
    if submitter.user_type == 'human'
      redirect_to workflow_execution_path(workflow_execution)
    else
      namespace = Namespace.find_by(puid: submitter.first_name)
      redirect_to namespace_project_workflow_execution_path(namespace.parent, namespace.project, workflow_execution)
    end
  end
end
