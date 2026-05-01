# frozen_string_literal: true

class ComboboxDatepickerComponentPreview < ViewComponent::Preview
  include ViewHelper

  def default
    render_with_template(locals: { id: 'test_id', input_name: 'test_input_name' })
  end

  def with_no_min_date
    render_with_template(locals: { id: 'test_id', input_name: 'test_input_name', min_date: nil })
  end

  def with_selected_date
    render_with_template(locals: { id: 'test_id', input_name: 'test_input_name',
                                   selected_date: Time.zone.today + 7.days })
  end

  def with_selected_date_and_no_min_date
    render_with_template(locals: { id: 'test_id', input_name: 'test_input_name',
                                   selected_date: Time.zone.today + 7.days, min_date: nil })
  end
end
