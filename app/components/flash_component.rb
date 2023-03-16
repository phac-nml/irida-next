# frozen_string_literal: true

# View Component for UI flash messages
class FlashComponent < ViewComponent::Base
  # rubocop:disable Lint/MissingSuper
  def initialize(type:)
    @type = type.to_sym
    @icon = icon_for_flash
    @classes = classes_for_flash
  end
  # rubocop:enable Lint/MissingSuper

  def classes_for_flash
    case @type
    when :error
      'bg-red-100 text-red-700'
    when :success
      'bg-green-100 text-green-700'
    when :warning
      'bg-yellow-100 text-yellow-700'
    else
      'bg-blue-100 text-blue-700'
    end
  end

  def icon_for_flash
    case @type
    when :error || :warning
      'icons/exclamation_triangle'
    when :info
      'icons/information_circle'
    when :success
      'icons/check'
    else
      'icons/exclamation_circle'
    end
  end
end
