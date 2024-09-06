# frozen_string_literal: true

# Common file import actions
module FileImportActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def create
    authorize! @namespace, to: :update_sample_metadata?
    @imported_metadata = ::Samples::Metadata::FileImportService.new(@namespace, current_user,
                                                                    file_import_params).execute
    if @namespace.errors.empty?
      render status: :ok, locals: { type: :success, message: t('concerns.file_import_actions.create.success') }
    elsif @namespace.errors.include?(:sample)
      errors = @namespace.errors.messages_for(:sample)
      render status: :partial_content,
             locals: { type: :alert, message: t('concerns.file_import_actions.create.error'), errors: }
    else
      error = @namespace.errors.full_messages_for(:base).first
      render status: :unprocessable_entity, locals: { type: :danger, message: error }
    end
  end

  private

  def file_import_params
    params.require(:file_import).permit(:file, :sample_id_column, :ignore_empty_values)
  end
end
