# frozen_string_literal: true

# Common file import actions
module SampleFileImportActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def new
    @broadcast_target = "samples_import_#{SecureRandom.uuid}"
  end

  def create # rubocop:disable Metrics/AbcSize
    @broadcast_target = params[:broadcast_target]

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_import_params[:file],
      filename: file_import_params[:file].original_filename,
      content_type: file_import_params[:file].content_type
    )

    ::Samples::BatchSampleImportJob.set(
      wait_until: 1.second.from_now
    ).perform_later(
      @namespace, current_user,
      @broadcast_target, blob.id, file_import_params.except(:file)
    )

    render status: :ok
  end

  private

  def file_import_params
    params.require(:file_import).permit(:file, :sample_id_column, :project_puid_column, :sample_description_column)
  end
end
