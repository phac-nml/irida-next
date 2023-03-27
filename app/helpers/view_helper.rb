# frozen_string_literal: true

module ViewHelper
  def class_names(*args)
    classes = []
    args.each do |class_name|
      case class_name
      when String
        classes << class_name if class_name.present?
      when Hash
        class_name.each do |key, value|
          classes << key.to_s if value
        end
      when Array
        classes += class_names(*class_name).presence
      end
    end
    classes.compact.uniq.join(' ')
  end

  def heroicons_source(icon_name)
    path = Rails.root.join('app', 'assets', 'icons', 'heroicons', "#{icon_name}.svg")
    file = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(file)
    svg = doc.at_css 'svg'
    svg[:class] = 'w-5 h-5'
    svg[:focusable] = false
    svg[:'aria-hidden'] = true
    doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
