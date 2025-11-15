# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

module Pathogen
  module Typography
    # Component for rendering callout text (18px)
    #
    # Callout text sits between body (16px) and lead (20px), perfect for emphasized
    # paragraphs, pull quotes, or sidebar content that needs more prominence than
    # body text but isn't quite a lead paragraph. Supports optional responsive sizing.
    #
    # @example Basic callout
    #   <%= render Pathogen::Typography::Callout.new do %>
    #     This is an important callout that draws attention.
    #   <% end %>
    #
    # @example Responsive sizing
    #   <%= render Pathogen::Typography::Callout.new(responsive: true, variant: :muted) do %>
    #     Scales from 16px (mobile) to 18px (desktop)
    #   <% end %>
    class Callout < Component
      include Shared

      DEFAULT_TAG = :p

      attr_reader :tag, :variant, :responsive

      # Initialize a new Callout component
      #
      # @param tag [Symbol] HTML tag to use (default: :p)
      # @param variant [Symbol] Color variant (:default, :muted, :subdued, :inverse)
      # @param responsive [Boolean] Enable responsive sizing (default: false)
      # @param system_arguments [Hash] Additional HTML attributes
      def initialize(tag: DEFAULT_TAG, variant: Shared::DEFAULT_VARIANT, responsive: false, **system_arguments)
        @tag = tag
        @variant = variant
        @responsive = responsive
        @system_arguments = system_arguments

        @system_arguments[:class] = class_names(
          system_arguments[:class],
          size_classes,
          color_classes_for_variant(@variant),
          Constants::LINE_HEIGHTS[:body],
          Constants::FONT_FAMILIES[:ui]
        )
      end

      private

      def size_classes
        if @responsive
          responsive_sizes = Constants::TEXT_RESPONSIVE_SIZES[:callout]
          "#{responsive_sizes[:mobile]} sm:#{responsive_sizes[:desktop]}"
        else
          'text-lg'  # 18px - between base (16px) and xl (20px)
        end
      end
    end
  end
end
