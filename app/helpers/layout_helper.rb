# frozen_string_literal: true

# 🧩 LayoutHelper: Nested Layout Magic! 🪄
#
# This module allows a layout to be rendered inside another layout (nested layouts).
# Perfect for creating complex page structures while keeping your code DRY.
#
# Source inspiration: https://railsdesigner.com/rails-layouts/
module LayoutHelper
  # 📦 Renders the current layout inside a parent layout
  #
  # @param layout [String] the name of the parent layout (without .html.erb extension)
  # @return [String] the rendered output
  # @raise [ArgumentError] if layout is nil or empty
  # @example
  #   <%= parent_layout 'application' %>
  def parent_layout(layout)
    # Validate input
    raise ArgumentError, 'Layout name cannot be nil or empty' if layout.nil? || layout.strip.empty?

    # Store current output buffer in the layout view flow
    view_flow.set(:layout, output_buffer)

    begin
      # Render the parent layout
      output = render template: "layouts/#{layout}"
      # Set the output buffer to the rendered parent layout
      self.output_buffer = ActionView::OutputBuffer.new(output)
    rescue StandardError => e
      Rails.logger.error "❌ Error rendering parent layout '#{layout}': #{e.message}"
      raise
    end
  end
end
