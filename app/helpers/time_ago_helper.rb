# frozen_string_literal: true

# Adds span including a title attribute with the date
module TimeAgoHelper
  def time_ago(current_time, original_time)
    viral_tooltip(title: l(original_time, format: :long)) do
      "<span class='text-sm'>#{distance_of_time_in_words(current_time, original_time)}</span>".html_safe
    end
  end
end
