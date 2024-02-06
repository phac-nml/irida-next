# frozen_string_literal: true

class HistoryVersionComponentPreview < ViewComponent::Preview
  # Default version changes display where values are strings
  # ---------------------------
  #
  def default
    project_namespace = Project.first.namespace
    @log_data = project_namespace.log_data_with_changes(1)

    render_with_template(locals: {
                           log_data: @log_data
                         })
  end
end
