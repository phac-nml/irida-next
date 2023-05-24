# frozen_string_literal: true

class ModalComponentPreview < ViewComponent::Preview
  def default
    render Viral::ModalComponent.new(title: 'This is a modal title') do |modal|
      modal.body do
        'This is a modal body'
      end
    end
  end
end
