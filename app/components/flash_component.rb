# frozen_string_literal: true

# View Component for UI flash messages
class FlashComponent < ViewComponent::Base
  # rubocop:disable Lint/MissingSuper
  def initialize(type:, data:)
    @type = type
    @data = data
    @icon = icon_for_flash
    @classes = classes_for_flash
  end

  # rubocop:enable Lint/MissingSuper

  def classes_for_flash
    case @type
    when :success
      'bg-green-100 dark:bg-green-800 dark:text-green-200'
    when :error
      'bg-red-100 dark:bg-red-800 dark:text-red-200'
    when :warning
      'bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-200'
    else
      'bg-blue-100 dark:bg-blue-800 dark:text-blue-200'
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
