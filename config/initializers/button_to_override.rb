# frozen_string_literal: true

# Override for rails button_to, which moves button outside of the form so that screenreaders don't announce that the
# button is inside a form which can be confusing to users
module ButtonToOverride
  def button_to(name = nil, options = nil, html_options = {}, &)
    # 1. Safely normalize html_options if a block is passed
    html_options = options || {} if block_given?

    html_options[:form] ||= {}
    html_options[:form][:id] ||= SecureRandom.uuid
    form_id = html_options[:form][:id]

    button_to_fragment = Nokogiri::HTML::DocumentFragment.parse(super)

    button_fragment = button_to_fragment.at_css('button').remove
    button_fragment['form'] = form_id
    button_to_fragment.add_child(button_fragment)

    button_to_fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end
end

ActionView::Helpers::UrlHelper.prepend(ButtonToOverride)
