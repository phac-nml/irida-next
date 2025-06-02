# frozen_string_literal: true

# Controller actions for Data Exports
class DataExportsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include BreadcrumbNavigation
  include ListActions
  include Metadata

  before_action :data_export, only: %i[destroy show]
  before_action :data_exports, only: %i[destroy]
  before_action :namespace, only: :new
  before_action :current_page
  before_action :set_default_tab, only: :show
  before_action :page_title

  TABS = %w[summary preview].freeze

  def index
    all_data_exports = load_data_exports
    @has_data_exports = all_data_exports.count.positive?
    @q = all_data_exports.ransack(params[:q])
    set_default_sort
    @pagy, @data_exports = pagy(@q.result)
  end

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
      render status: :unprocessable_entity,
             locals: { type: 'alert', message: error_message(@data_export),
                       export_type: data_export_params['export_type'] }
    else
      flash[:success] = t('.success', name: @data_export.name || @data_export.id)
      redirect_to data_export_path(@data_export), status: :see_other
    end
  end

  def redirect
    if params['identifier'].include?('INXT_SAM')
      redirect_to_sample
    elsif params['identifier'].include?('INXT_PRJ')
      redirect_to_project
    else
      redirect_to_workflow_execution
    end
  end

  def destroy
    DataExports::DestroyService.new(@data_export, current_user).execute
    respond_to do |format|
      format.turbo_stream do
        if @data_export.persisted?
          render status: :unprocessable_entity,
                 locals: { type: 'alert',
                           message: t('.error', name: @data_export.name || @data_export.id) }
        else
          flash[:success] = t('.success', name: @data_export.name || @data_export.id)
          redirect_to data_exports_path
        end
      end
    end
  end

  private

  def set_default_sort
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end

  def data_export_params
    params.expect(data_export: [:name, :export_type, :email_notification,
                                { export_parameters: [:linelist_format, :namespace_id, :analysis_type,
                                                      { ids: [], metadata_fields: [], attachment_formats: [] }] }])
  end

  def data_export
    @data_export = DataExport.find(params[:id])
  end

  def data_exports
    @data_exports = load_data_exports
  end

  def load_data_exports
    DataExport.where(user: current_user)
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
      templates = metadata_templates_ancestral.map do |template|
        { id: template.id, name: template.name, fields: template.fields }
      end
      { open: true, namespace_id: params[:namespace_id], templates: templates }
    end
  end

  def analysis_locals
    local = { open: true,
              analysis_type: params['analysis_type'],
              namespace_id: %w[group project].include?(params['analysis_type']) ? params[:namespace_id] : nil }
    local[:workflow_execution] = WorkflowExecution.find(params[:workflow_execution_id]) if params[:single_workflow]
    local
  end

  def redirect_to_sample
    sample = Sample.find_by(puid: params['identifier'])
    project = Project.find(sample.project_id)
    namespace = project.namespace.parent
    redirect_to namespace_project_sample_path(namespace, project, sample, tab: 'files')
  end

  def redirect_to_project
    project = Namespace.find_by(puid: params['identifier']).project
    redirect_to namespace_project_path(project.parent, project)
  end

  def redirect_to_workflow_execution
    workflow_execution = WorkflowExecution.find_by(id: params['identifier'])
    if workflow_execution.submitter == current_user
      redirect_to workflow_execution_path(workflow_execution)
    else
      namespace = workflow_execution.namespace
      if namespace.type == 'Group'
        redirect_to group_workflow_execution_path(namespace, workflow_execution)
      else
        redirect_to namespace_project_workflow_execution_path(namespace.parent, namespace.project, workflow_execution)
      end
    end
  end

  def page_title
    @title = case action_name
             when 'index'
               t(:'general.default_sidebar.data_exports').to_s
             when 'show'
               if @tab == 'preview'
                 [t(:'data_exports.show.tabs.preview'),
                  "#{t(:'data_exports.show.page_title')} #{@data_export.id}"].join(' · ')
               else
                 [t(:'data_exports.show.tabs.summary'),
                  "#{t(:'data_exports.show.page_title')} #{@data_export.id}"].join(' · ')
               end
             else
               t(:'general.default_sidebar.data_exports')
             end
  end
end
