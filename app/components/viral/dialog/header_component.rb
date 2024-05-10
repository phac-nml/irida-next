# frozen_string_literal: true

module Viral
  module Dialog
    # Header component for dialog dialog
    class HeaderComponent < Viral::BaseComponent
      attr_reader :title, :closable

      def initialize(title:, closable: true)
        @title = title
        @closable = closable
      end
    end
  end
end
