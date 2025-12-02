# frozen_string_literal: true

# Common metadata template actions
module MetadataTemplateActions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include Metadata

  included do
    before_action proc { namespace }
    before_action proc { metadata_template }, only: %i[destroy edit show update]
    before_action proc { metadata_template_fields }, only: %i[create new edit update]
    before_action proc { metadata_templates_ancestral }, only: %i[list]
    before_action proc { view_authorizations }, only: %i[index update]
  end

  def index
    authorize! @namespace, to: :view_metadata_templates?

    @q = load_namespace_metadata_templates.ransack(params[:q])
    set_default_sort
    @pagy, @metadata_templates = pagy(@q.result)
  end

  def new
    authorize! @namespace, to: :create_metadata_templates?
    @metadata_template = MetadataTemplate.new(namespace_id: @namespace.id)

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

  def create # rubocop:disable Metrics/MethodLength
    @metadata_template = MetadataTemplates::CreateService.new(
      current_user, @namespace, metadata_template_params
    ).execute

    respond_to do |format|
      format.turbo_stream do
        if @metadata_template.persisted?
          render_success(I18n.t('concerns.metadata_template_actions.create.success',
                                template_name: @metadata_template.name))
        else
          error_msg = if @metadata_template.errors.size == 1 && @metadata_template.errors[:fields].any?
                        error_message(@metadata_template)
                      else
                        t(:'general.form.error_notification')
                      end
          render_error(error_msg)
        end
      end
    end
  end

  def destroy
    MetadataTemplates::DestroyService.new(current_user, @metadata_template).execute
    respond_to do |format|
      format.turbo_stream do
        if @metadata_template.deleted?
          render_success(I18n.t('concerns.metadata_template_actions.destroy.success',
                                template_name: @metadata_template.name))
        else
          render_error(error_message(@metadata_template))
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
    authorize! @namespace, to: :view_metadata_templates?
    current_metadata_template_id
    set_pagination_params
    set_search_url

    respond_to do |format|
      format.html do
        render 'shared/samples/metadata_templates_list'
      end
    end
  end

  protected

  def metadata_templates_path
    raise NotImplementedError
  end

  private

  def view_authorizations
    @allowed_to = {
      update_metadata_templates:
      allowed_to?(:update_metadata_templates?, @namespace),
      destroy_metadata_templates:
      allowed_to?(:destroy_metadata_templates?, @namespace),
      create_metadata_templates:
      allowed_to?(:create_metadata_templates?, @namespace)
    }
  end

  def load_namespace_metadata_templates
    authorized_scope(MetadataTemplate, type: :relation, scope_options: { namespace: @namespace })
  end

  def metadata_template
    @metadata_template = MetadataTemplate.find_by(id: params[:id], namespace: @namespace)
  end

  def metadata_template_fields
    @max_metadata_columns = Metadata::MAX_METADATA_COLUMNS

    @current_template_fields = if params.key?(:metadata_template) && metadata_template_params.key?(:fields)
                                 metadata_template_params[:fields]
                               else
                                 @metadata_template.nil? ? [] : @metadata_template.fields
                               end
    @available_metadata_fields = @namespace.metadata_fields - @current_template_fields
  end

  def render_success(message)
    render status: :ok, locals: {
      type: 'success',
      message:
    }
  end

  def render_error(message)
    render status: :unprocessable_content,
           locals: {
             type: 'alert',
             message:
           }
  end

  def set_default_sort
    @q.sorts = 'name asc' if @q.sorts.empty?
  end

  def current_metadata_template_id
    default_values = %w[none all]
    @current_metadata_template_id = if default_values.include?(params[:metadata_template])
                                      params[:metadata_template]
                                    else
                                      MetadataTemplate.find(params[:metadata_template]).id
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
