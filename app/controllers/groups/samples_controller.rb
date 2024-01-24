# frozen_string_literal: true

module Groups
  # Controller actions for Samples within a Group
  class SamplesController < ApplicationController
    layout 'groups'
    include Metadata
    before_action :group, :current_page, only: %i[index]
    before_action only: %i[index] do
      fields_for_namespace(@group, params[:metadata].to_i)
    end

    def index
      authorize! @group, to: :sample_listing?

      @q = authorized_samples.ransack(params[:q])

      set_default_sort

      @pagy, @samples = pagy(@q.result)
      respond_to do |format|
        format.html do
          @has_samples = @q.result.count.positive?
        end
        format.turbo_stream
      end
    end

    private

    def group
      @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
    end

    def authorized_samples
      authorized_scope(Sample, type: :relation, as: :group_samples, scope_options: { group: @group })
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: I18n.t('groups.samples.index.title'),
          path: group_samples_path
        }]
      end
    end

    def current_page
      @current_page = 'samples'
    end

    def set_default_sort
      @q.sorts = 'updated_at desc' if @q.sorts.empty?
    end
  end
end
