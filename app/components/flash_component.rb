# frozen_string_literal: true

# View Component for UI flash messages
class FlashComponent < ViewComponent::Base
  def initialize(type:, data:)
    @type = type
    @data = data
    @icon = icon_for_flash
    @classes = classes_for_flash
  end

  def classes_for_flash
    case @type
    when 'error'
      'bg-red-600 dark:bg-red-800'
    when 'success'
      'bg-green-700 dark:bg-green-900'
    when 'warning'
      'bg-yellow-600 dark:bg-yellow-900'
    else
      'bg-blue-600 dark:bg-blue-800'
    end
  end

  def icon_for_flash
    case @type
    when 'error'
      'icons/exclamation_circle'
    when 'success'
      'icons/check'
    when 'warning'
      'icons/exclamation_triangle'
    else
      'icons/information_circle'
    end
  end
end
