# frozen_string_literal: true

# Common metadata template actions
module MetadataTemplateActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { metadata_template }, only: %i[destroy edit show update]
  end

  def index
    authorize! @namespace, to: :view_metadata_templates?

    @metadata_templates = load_metadata_templates

    @q = load_metadata_templates.ransack(params[:q])
    set_default_sort
    @pagy, @metadata_templates = pagy(@q.result)
  end

  def new
    authorize! @namespace, to: :create_metadata_templates?

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def edit
    authorize! @namespace, to: :update_metadata_templates?

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
    @metadata_template = MetadataTemplates::CreateService.new(
      current_user, @namespace, metadata_template_params
    ).execute

    respond_to do |format|
      format.turbo_stream do
        if @metadata_template.persisted?
          render_success(I18n.t('concerns.metadata_template_actions.create.success',
                                template_name: @metadata_template.name))
        else
          render_error(@metadata_template.errors.full_messages.first)
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
          render_error(@metadata_template.errors.full_messages.first)
        end
      end
    end
  end

  def update
    @updated = MetadataTemplates::UpdateService.new(current_user, @metadata_template, metadata_template_params).execute

    respond_to do |format|
      if @updated
        format.turbo_stream do
          render_success(I18n.t('concerns.metadata_template_actions.update.success',
                                template_name: @metadata_template.name))
        end
      else
        format.turbo_stream do
          render_error(I18n.t('concerns.metadata_template_actions.update.error',
                              template_name: @metadata_template.name))
        end
      end
    end
  end

  protected

  def metadata_templates_path
    raise NotImplementedError
  end

  private

  def load_metadata_templates
    @metadata_templates = MetadataTemplate.where(namespace: @namespace)
  end

  def metadata_template
    @metadata_template = MetadataTemplate.find_by(id: params[:id], namespace: @namespace)
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
end
