# frozen_string_literal: true

module Samples
  # controller for sample metadata
  class MetadataController < ApplicationController # rubocop:disable Metrics/ClassLength
    respond_to :turbo_stream

    before_action :sample
    before_action :project
    before_action :field

    def update
      authorize! @project, to: :update_sample?

      value = params[:value]
      cell_id = params[:cell_id]

      if @sample.field?(@field)
        update_field_value(@sample.metadata[@field], value, cell_id)
      else
        create_metadata_field(@field, value, cell_id)
      end
    end

    # Param received as:
    # params: {sample: {create_fields: {key1: value1, key2: value2, ...}}}
    def bulk_create
      authorize! @project, to: :update_sample?
      @allowed_to = { update_sample: true }
      create_metadata_fields =
        ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user,
                                                       create_field_params['create_fields']).execute

      if @sample.errors.any?
        render status: :unprocessable_entity, locals: { type: 'error', message: error_message(@sample) }
      else
        @status = get_create_status(create_metadata_fields[:added_keys], create_metadata_fields[:existing_keys])
        @messages = get_create_messages(create_metadata_fields[:added_keys], create_metadata_fields[:existing_keys])
        render status: @status
      end
    end

    # Param is received as:
    # params: {sample: {update_field: {key: {old_key: new_key}, value: {old_value: new_value}}}
    # Fields that have not been changed will have equal old and new
    def bulk_update # rubocop:disable Metrics/AbcSize
      authorize! @project, to: :update_sample?
      @allowed_to = { update_sample: true }
      updated_metadata_field = ::Samples::Metadata::Fields::UpdateService.new(@project, @sample, current_user,
                                                                              update_field_params).execute
      if @sample.errors.any?
        render status: :unprocessable_entity,
               locals: { key: update_field_params['update_field']['key'].keys[0],
                         value: update_field_params['update_field']['value'].keys[0] }
      else
        update_render_params = get_update_status_and_message(updated_metadata_field)
        render status: update_render_params[:status], locals: { type: update_render_params[:message][:type],
                                                                message: update_render_params[:message][:message] }
      end
    end

    private

    def sample
      @sample = Sample.includes(:project).find_by(id: params[:sample_id]) || not_found
    end

    def project
      @project = @sample.project
    end

    def field
      @field = params[:id]
    end

    def create_field_params
      params.expect(sample: [create_fields: {}])
    end

    def update_field_params
      params.expect(sample: [update_field: { key: {}, value: {} }])
    end

    def get_create_status(added_keys, existing_keys)
      if added_keys.count.positive? && existing_keys.count.positive?
        :multi_status
      elsif existing_keys.count.positive?
        :unprocessable_entity
      else
        :ok
      end
    end

    def get_create_messages(added_keys, existing_keys) # rubocop:disable Metrics/MethodLength
      messages = []
      if added_keys.count == 1
        messages << { type: 'success',
                      message: t('projects.samples.metadata.fields.create.single_success', key: added_keys[0]) }
      elsif added_keys.count.positive?
        messages << { type: 'success',
                      message: t('projects.samples.metadata.fields.create.multi_success',
                                 keys: added_keys.join(', ')) }
      end

      if existing_keys.count == 1
        messages << { type: 'error',
                      message: t('projects.samples.metadata.fields.create.single_key_exists',
                                 key: existing_keys[0]) }
      elsif existing_keys.count.positive?
        messages << { type: 'error',
                      message: t('projects.samples.metadata.fields.create.multi_keys_exists',
                                 keys: existing_keys.join(', ')) }
      end
      messages
    end

    def get_update_status_and_message(updated_metadata_field)
      update_render_params = {}
      modified_metadata = updated_metadata_field[:added] + updated_metadata_field[:updated] +
                          updated_metadata_field[:deleted]
      if modified_metadata.count.positive?
        update_render_params[:status] = :ok
        update_render_params[:message] =
          { type: 'success', message: t('projects.samples.metadata.fields.update.success') }
      else
        update_render_params[:status] = :unprocessable_entity
        update_render_params[:message] = { type: 'error', message: error_message(@sample) }
      end
      update_render_params
    end

    def create_metadata_field(field, value, cell_id)
      create_params = { field => value }
      ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user, create_params).execute

      if @sample.errors.any?
        render_update_error(cell_id)
      else
        render_update_success(cell_id)
      end
    end

    def update_field_value(original_value, new_value, cell_id)
      perform_field_update(original_value, new_value)

      if @sample.errors.any?
        render_update_error(cell_id)
      else
        render_update_success(cell_id)
      end
    end

    def perform_field_update(original_value, new_value)
      ::Samples::Metadata::Fields::UpdateService.new(
        @project,
        @sample,
        current_user,
        build_update_params(original_value, new_value)
      ).execute
    end

    def build_update_params(original_value, new_value)
      {
        'update_field' => {
          'key' => { @field => @field },
          'value' => { original_value => new_value }
        }
      }
    end

    def render_update_error(cell_id)
      # render status: :unprocessable_entity,
      #       locals: { type: 'error', message: error_message(@sample) }
      render turbo_stream: [
        turbo_stream.update(
          cell_id, @sample.metadata[@field]
        ),
        turbo_stream.append(
          'flashes',
          partial: 'shared/flash',
          locals: { type: 'error',
                    message: error_message(@sample) }
        )
      ]
    end

    def render_update_success(cell_id)
      # When the timestamp is rendered to the form, it only renders down to the second, this was causing timing
      # issues for selecting current samples.  To fix this, we are adding a second to the timestamp so that the
      # timestamp is always greater than the current time.
      @timestamp = @sample.updated_at + 1.second
      render turbo_stream: [
        turbo_stream.replace(
          cell_id, Samples::EditableCell.new(field: @field, sample: @sample)
        ),
        turbo_stream.append(
          'flashes',
          partial: 'shared/flash',
          locals: { type: 'success',
                    message: t('samples.editable_cell.update_success') }
        ),
        turbo_stream.replace('timestamp', partial: 'shared/samples/timestamp_input')
      ]
    end
  end
end
