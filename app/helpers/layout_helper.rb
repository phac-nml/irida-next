# frozen_string_literal: true

# Allows a layout to be rendered in a parent layout
# From: https://railsdesigner.com/rails-layouts/
module LayoutHelper
  def parent_layout(layout)
    view_flow.set(:layout, output_buffer)
    output = render template: "layouts/#{layout}"
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end
end
