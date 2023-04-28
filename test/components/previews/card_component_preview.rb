# frozen_string_literal: true

class CardComponentPreview < ViewComponent::Preview
  def default
    render Viral::CardComponent.new(title: 'Simple card with Title') do
      'This is a card'
    end
  end

  def card_with_header_actions
    render Viral::CardComponent.new(title: 'Card with header actions') do |card|
      card.header(title: 'This is a card with header actions') do |header|
        header.action do
          content_tag('a', 'Edit', class: 'font-medium text-blue-600 dark:text-blue-500 hover:underline cursor-pointer')
        end
        header.action do
          content_tag('a', 'Delete', class: 'font-medium text-red-600 dark:text-red-500 hover:underline cursor-pointer')
        end
        'Just the body here'
      end
    end
  end

  def card_with_simple_header
    render Viral::CardComponent.new do |card|
      card.header(title: 'This is a card with a simple header')
    end
  end

  def card_with_multiple_sections
    render Viral::CardComponent.new do |card|
      card.header(title: 'This is a card with multiple sections')
      card.section { 'This is section 1 content' }
      card.section(border_top: true) { 'This is section 2 content' }
    end
  end

  def card_with_titled_sections
    render Viral::CardComponent.new do |card|
      card.header(title: 'This is a card with multiple titled sections')
      card.section(title: 'Section 1') { 'This is section 1 content' }
      card.section(title: 'Section 2', border_top: true) { 'This is section 2 content' }
    end
  end

  def card_section_with_action
    render Viral::CardComponent.new do |card|
      card.header(title: 'This is a card with a section with an action')
      card.section { 'John Dow' }
      card.section(title: 'Contact Information', border_top: true) do |section|
        section.action do
          content_tag('a', 'Edit', class: 'font-medium text-blue-600 dark:text-blue-500 hover:underline cursor-pointer')
        end
        'john.doe@example.com'
      end
    end
  end
end
