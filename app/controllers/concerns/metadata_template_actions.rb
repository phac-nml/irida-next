# frozen_string_literal: true

# Common metadata template actions
module MetadataTemplateActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
    before_action proc { metadata_template }, only: %i[destroy edit show update]
  end

  def index
    authorize! @namespace, to: :view_metadata_templates?

    @metadata_templates = load_metadata_templates
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
    # @metadata_template = MetadataTemplates::CreateService.new(current_user, @namespace, metadata_templates_params)

    # respond_to do |format|
    #   format.turbo_stream do
    #     if @metadata_template.persisted?
    #       render status: :ok, locals: {
    #         type: 'success',
    #         message: I18n.t('.success', template_name: @metadata_template.name)
    #       }
    #     else
    #       render status: :unprocessable_entity,
    #              locals:
    #             { type: 'alert',
    #               message: @metadata_template.errors.full_messages.first }

    #     end
    #   end
    # end
    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def destroy
    # MetadataTemplates::DestroyService.new(current_user, @metadata_template).execute
    # respond_to do |format|
    #   format.turbo_stream do
    #     if @metadata_template.deleted?
    #       flash[:success] = I18n.t('.success', template_name: @metadata_template.name)
    #       redirect_to metadata_templates_path
    #     else
    #       render status: :unprocessable_entity,
    #              locals: {
    #                type: 'alert',
    #                message: @metadata_template.errors.full_messages.first
    #              }
    #     end
    #   end
    # end
    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end

  def update
    # @updated = MetadataTemplate::UpdateService.new(current_user, @metadata_template, metadata_template_params).execute

    # respond_to do |format|
    #   if @updated
    #     format.turbo_stream do
    #       render status: :ok, locals: { type: 'success',
    #                                     message: I18n.t('.success', template_name: @metadata_template.name) }
    #     end
    #   else
    #     format.turbo_stream do
    #       render status: :unprocessable_entity,
    #              locals: { type: 'alert',
    #                        message: I18n.t('.error', template_name: @metadata_template.name) }
    #     end
    #   end
    # end
    respond_to do |format|
      format.turbo_stream do
        render status: :ok
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
end
