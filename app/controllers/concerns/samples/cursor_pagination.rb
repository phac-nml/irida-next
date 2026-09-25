# frozen_string_literal: true

module Samples
  # Project-only cursor browsing. Row requests carry their entire query and never write search preferences.
  module CursorPagination
    extend ActiveSupport::Concern

    private

    def cursor_rows
      return head :not_found unless @cursor_mode
      return render json: { error: 'invalid_query' }, status: :unprocessable_content unless @query.valid?

      @cursor_page = build_cursor_page(cursor: params[:cursor])
      @samples = @cursor_page.records
      response.headers['Cache-Control'] = 'private, no-store'
      render :rows
    rescue ::Samples::CursorPage::InvalidCursor
      render json: { error: 'invalid_cursor' }, status: :unprocessable_content
    rescue ::Samples::CursorPage::InvalidQuery
      render json: { error: 'invalid_query' }, status: :unprocessable_content
    end

    def set_cursor_mode
      @cursor_mode = cursor_library_available? && Flipper.enabled?(:data_grid_samples_table, Current.user) &&
                     params[:table_view] != 'standard'
    end

    def cursor_library_available?
      Pathogen::DataGridComponent.method_defined?(:virtual_cursor_pagination?)
    end

    def cursor_search_params
      params.fetch(:q, ActionController::Parameters.new)
            .permit(:name_or_puid_cont, :metadata_template, :sort, :groups_attributes, groups_attributes: {})
            .to_h.with_indifferent_access.tap { |query_params| query_params[:sort] ||= 'updated_at desc' }
    end

    def build_cursor_page(cursor: nil)
      ::Samples::CursorPage.new(query: @query, project: @project, query_params: @search_params.to_h,
                                limit: params[:limit], cursor:).call
    end

    def load_cursor_results
      @has_samples = @project.samples.exists?
      @pagy = nil
      return invalid_cursor_query if @query.invalid?

      @cursor_page = build_cursor_page
      @cursor_total_count = @query.results.where(project_id: @project.id).reorder(nil).count
      @samples = @cursor_page.records
      @virtual_pagination = cursor_pagination
      @cursor_sort_message = cursor_sort_announcement
    rescue ::Samples::CursorPage::InvalidQuery
      invalid_cursor_query
    end

    def invalid_cursor_query
      @samples = []
      @cursor_query_error = I18n.t('projects.samples.cursor.invalid_query')
      response.status = :unprocessable_content
    end

    def cursor_sort_announcement
      column = if @query.column.start_with?('metadata.')
                 @query.column.delete_prefix('metadata.')
               else
                 I18n.t("samples.table_component.#{@query.column}")
               end
      return I18n.t('projects.samples.cursor.sorted_asc', column:) if @query.direction == 'asc'

      I18n.t('projects.samples.cursor.sorted_desc', column:)
    end

    def cursor_pagination
      {
        mode: :cursor, next_cursor: @cursor_page.next_cursor, total_count: @cursor_total_count,
        page_size: @cursor_page.limit, row_offset: 0,
        rows_url: rows_namespace_project_samples_path(@project.namespace.parent, @project),
        search_params: { q: @search_params.to_h },
        refresh_url: namespace_project_samples_path(@project.namespace.parent, @project,
                                                    q: @search_params.to_h, limit: @cursor_page.limit)
      }
    end
  end
end
