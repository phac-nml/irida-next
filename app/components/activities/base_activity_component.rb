# frozen_string_literal: true

module Activities
  # Component for base activity component to initialize activity and to contain common methods
  class BaseActivityComponent < Component
    include PathHelper

    def initialize(activity: nil)
      @activity = activity
    end

    def highlighted_text(text)
      content_tag(:span, text, class: highlighted_count_classes)
    end

    def highlighted_count_classes
      'text-slate-800 dark:text-slate-300 font-medium'
    end

    def active_link_classes
      'text-slate-800 dark:text-slate-300 font-medium hover:underline'
    end

    def more_details_button_classes
      'button button-default'
    end

    def more_details_button(dialog_type, descriptive_text)
      button_to t(:'components.activity.more_details'),
                activity_path(@activity[:id]),
                params: { dialog_type: dialog_type },
                data: { turbo_stream: true },
                method: :get,
                class: more_details_button_classes,
                title: descriptive_text
    end
  end
end
