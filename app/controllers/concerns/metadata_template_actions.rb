# frozen_string_literal: true

# Common metadata template actions
module MetadataTemplateActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { metadata_template }, only: %i[destroy edit show update]
    before_action proc { metadata_template_fields }, only: %i[create new edit update]
    before_action proc { metadata_templates }, only: %i[list]
  end

  def index
    authorize! @namespace, to: :view_metadata_templates?

    @q = load_metadata_templates.ransack(params[:q])
    set_default_sort
    @pagy, @metadata_templates = pagy(@q.result)
  end

  def new
    authorize! @namespace, to: :create_metadata_templates?
    @new_template = MetadataTemplate.new(namespace_id: @namespace.id)

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def edit
    authorize! @metadata_template, to: :update_metadata_template?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def show
    authorize! @namespace, to: :view_metadata_templates?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def create
    @new_template = MetadataTemplates::CreateService.new(
      current_user, @namespace, metadata_template_params
    ).execute

    respond_to do |format|
      format.turbo_stream do
        if @new_template.persisted?
          render_success(I18n.t('concerns.metadata_template_actions.create.success',
                                template_name: @new_template.name))
        else
          render_error(error_message(@new_template))
        end
      end
    end
  end

  def destroy
    MetadataTemplates::DestroyService.new(current_user, @metadata_template).execute
    respond_to do |format|
      format.turbo_stream do
        if @metadata_template.deleted?
          flash[:success] =
            I18n.t('concerns.metadata_template_actions.destroy.success', template_name: @metadata_template.name)
          redirect_to metadata_templates_path
        else
          render_error(error_message(@new_template))
        end
      end
    end
  end

  def update # rubocop:disable Metrics/MethodLength
    @updated = MetadataTemplates::UpdateService.new(current_user, @metadata_template, metadata_template_params).execute

    respond_to do |format|
      if @updated
        format.turbo_stream do
          render_success(I18n.t('concerns.metadata_template_actions.update.success',
                                template_name: @metadata_template.name))
        end
      else
        msg = if @metadata_template.errors.any?
                @metadata_template.errors.full_messages.to_sentence
              else
                I18n.t('concerns.metadata_template_actions.update.error',
                       template_name: @metadata_template.name)
              end
        format.turbo_stream do
          render_error(msg)
        end
      end
    end
  end

  def list
    set_template_name
    set_pagination_params
    set_search_url

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('metadata_templates_dropdown',
                                                  partial: 'shared/samples/metadata_templates_list')
      end
    end
  end

  protected

  def metadata_templates_path
    raise NotImplementedError
  end

  private

  def metadata_templates
    @metadata_templates = authorized_scope(MetadataTemplate, type: :relation,
                                                             scope_options: { namespace: @namespace,
                                                                              include_ancestral_templates: true })
  end

  def load_metadata_templates
    authorized_scope(MetadataTemplate, type: :relation, scope_options: { namespace: @namespace })
  end

  def metadata_template
    @metadata_template = MetadataTemplate.find_by(id: params[:id], namespace: @namespace)
  end

  def metadata_template_fields
    @current_template_fields = if params.key?(:metadata_template) && metadata_template_params.key?(:fields)
                                 metadata_template_params[:fields]
                               else
                                 @metadata_template.nil? ? [] : @metadata_template.fields
                               end
    @available_metadata_fields = @namespace.metadata_fields.sort_by(&:downcase) - @current_template_fields
  end

  def render_success(message)
    render status: :ok, locals: {
      type: 'success',
      message:
    }
  end

  def render_error(message)
    render status: :unprocessable_entity,
           locals: {
             type: 'alert',
             message:
           }
  end

  def set_default_sort
    @q.sorts = 'name asc' if @q.sorts.empty?
  end

  def set_template_name
    default_values = %w[none all]
    @name = if default_values.include?(params[:metadata_template])
              I18n.t("shared.samples.metadata_templates.fields.#{params[:metadata_template]}")
            else
              MetadataTemplate.find(params[:metadata_template]).name
            end
  end

  def set_pagination_params
    @limit = params[:limit]
    @page = params[:page]
  end

  def set_search_url
    @url = @namespace.is_a?(Group) ? search_group_samples_url : search_namespace_project_samples_url
  end
end
