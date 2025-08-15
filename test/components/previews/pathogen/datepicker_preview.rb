# frozen_string_literal: true

module Pathogen
  class DatepickerPreview < ViewComponent::Preview
    include Pathogen::ViewHelper
    def default
      pathogen_datepicker(id: 'test_id', input_name: 'test_input_name')
    end

    def with_no_min_date
      pathogen_datepicker(id: 'test_id', input_name: 'test_input_name', min_date: nil)
    end

    def with_selected_date
      pathogen_datepicker(
        id: 'test_id',
        input_name: 'test_input_name',
        selected_date: Time.zone.today + 7.days
      )
    end

    def with_selected_date_and_no_min_date
      pathogen_datepicker(
        id: 'test_id',
        input_name: 'test_input_name',
        min_date: nil,
        selected_date: Time.zone.today + 7.days
      )
    end
  end
end
