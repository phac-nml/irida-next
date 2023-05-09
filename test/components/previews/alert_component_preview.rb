# frozen_string_literal: true

class AlertComponentPreview < ViewComponent::Preview
  def notice_alert
    render Viral::AlertComponent.new(message: 'This is a notice alert', type: 'notice')
  end

  def alert_alert
    render Viral::AlertComponent.new(message: 'This is an alert alert', type: 'alert')
  end
end
