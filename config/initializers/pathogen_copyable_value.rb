# frozen_string_literal: true

module Irida
  # Ensures Pathogen::CopyableValue renders valid HTML in host views.
  module PathogenCopyableValueRootElementOverride
    private

    def setup_system_arguments
      super
      # Pathogen::CopyableValue renders a tooltip element with a <div> root.
      # The default <span> container creates invalid markup (<div> inside <span>)
      # and fails W3C validation. Keep the component inline with classes, but
      # switch the semantic root to <div> for valid HTML.
      @system_arguments[:tag] = :div
    end
  end
end

Rails.application.reloader.to_prepare do
  next if Pathogen::CopyableValue < Irida::PathogenCopyableValueRootElementOverride

  Pathogen::CopyableValue.prepend(Irida::PathogenCopyableValueRootElementOverride)
end
