# frozen_string_literal: true

# Helper entry points for app-owned icon rendering and native rails_icons passthrough.
module IconHelper
  NATIVE_ICON_HELPER = RailsIcons::Helpers::IconHelper.instance_method(:icon)

  def rails_icon(...)
    NATIVE_ICON_HELPER.bind_call(self, ...)
  end

  def icon(*, **, &)
    render(IconComponent.new(*, **), &)
  end
end
