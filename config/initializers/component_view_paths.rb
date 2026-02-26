# frozen_string_literal: true

# Datepicker currently renders nested templates via `render partial: "viral/..."`.
# Those partials live in app/components, so ActionView must include this path.
# Keep host-app component paths configured here
# (required only for the DatePicker to work properly).
ActionController::Base.append_view_path Rails.root.join('app/components')
