# frozen_string_literal: true

class ModalComponentPreview < ViewComponent::Preview
  def try_me
    render 'components/modal'
  end

  def default
    render Viral::ModalComponent.new(title: 'This is a modal title') do |modal|
      modal.body do
        'This is a modal body'
      end
    end
  end

  def small
    render Viral::ModalComponent.new(title: 'This is a modal title', size: :small) do |modal|
      modal.body do
        'This is a modal body'
      end
    end
  end

  def large
    render Viral::ModalComponent.new(title: 'This is a modal title', size: :large) do |modal|
      modal.body do
        'This is a modal body'
      end
    end
  end

  def extra_large
    render Viral::ModalComponent.new(title: 'This is a modal title', size: :extra_large) do |modal|
      modal.body do
        'This is a modal body'
      end
    end
  end
end
