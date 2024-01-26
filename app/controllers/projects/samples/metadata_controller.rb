# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      def new
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'new_metadata_modal',
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def edit
        authorize! @project, to: :update_sample?
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'update_metadata_modal',
                                                 locals: {
                                                   open: true,
                                                   key: params[:key],
                                                   value: params[:value]
                                                 }), status: :ok
      end

      def create # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        new_metadata = validate_new_metadata(metadata_params['metadata'])
        flash_messages = {}

        unless new_metadata['to_add']['metadata'].empty?
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   new_metadata['to_add']).execute
          flash_messages[:success] =
            { type: 'success',
              message: t('.success', new_keys: metadata_fields[:added].join(', '), sample_name: @sample.name) }
        end

        if new_metadata['exists'].count.positive?
          flash_messages[:error] = { type: 'error',
                                     message: t('.error', existing_keys: new_metadata['exists'].join(', ')) }
        end

        status = get_add_status(flash_messages)
        respond_to do |format|
          format.turbo_stream do
            render status:, locals: { flash_messages:, table_listing: @sample.metadata_with_provenance }
          end
        end
      end

      def update # rubocop:disable Metrics/AbcSize
        authorize! @project, to: :update_sample?
        respond_to do |format|
          metadata_fields = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                   metadata_params).execute
          modified_metadata = metadata_fields[:added] + metadata_fields[:updated] + metadata_fields[:deleted]
          if modified_metadata.count.positive?
            flash[:success] =
              t('.success', metadata_fields: metadata_fields[:updated].join(', '), sample_name: @sample.name)
          end
          flash[:error] = @sample.errors.full_messages.first if @sample.errors.any?
          format.turbo_stream { redirect_to(project_path(@project)) }
        end
      end

      private

      def metadata_params
        params.require(:sample).permit(metadata: {})
      end

      def validate_new_metadata(metadata)
        validated_metadata = { 'to_add' => { 'metadata' => {} }, 'exists' => [] }
        metadata.each do |key, value|
          key_exists = validate_new_key(key)
          key_exists ? validated_metadata['exists'] << key : validated_metadata['to_add']['metadata'][key] = value
        end
        validated_metadata
      end

      # Checks to ensure the user has not changed a metadata key to one that already exists
      def validate_new_key(key)
        key_exists = false
        @sample.metadata.each do |k, _v|
          if k.downcase == key.downcase
            key_exists = true
            break
          end
        end
        key_exists
      end

      def get_add_messages(added_metadata, existing_metadata)
        messages = {}
        if added_metadata.count.positive?
          messages[:success] = { type: 'success',
                                 message: t('.success', new_keys: added_metadata.join(', '),
                                                        sample_name: @sample.name) }
        end

        if existing_metadata.count.positive?
          messages[:error] = { type: 'error',
                               message: t('.error', existing_keys: existing_metadata.join(', ')) }
        end
        get_add_status(messages)
      end

      def get_add_status(messages)
        if messages[:success] && (messages[:error] || @sample.errors.any?)
          :multi_status
        elsif messages[:success]
          :ok
        else
          :unprocessable_entity
        end
      end
    end
  end
end
