ActiveSupport.on_load(:action_view) do
  # Monkey patch CheckBox to remove autocomplete="off"
  ActionView::Helpers::Tags::CheckBox.class_eval do
    private

    remove_possible_method :hidden_field_for_checkbox

    def hidden_field_for_checkbox(options)
      if @unchecked_value
        tag('input',
            options.slice('name', 'disabled', 'form').merge!('type' => 'hidden',
                                                             'value' => @unchecked_value))
      else
        ''.html_safe
      end
    end
  end

  # Monkey patch FileField to remove autocomplete="off"
  ActionView::Helpers::Tags::FileField.class_eval do
    remove_possible_method :hidden_field_for_multiple_file

    private

    def hidden_field_for_multiple_file(options)
      tag('input', 'name' => options['name'], 'type' => 'hidden', 'value' => '')
    end
  end

  # Monkey patch HiddenField to remove autocomplete="off"
  ActionView::Helpers::Tags::HiddenField.class_eval do
    remove_possible_method :render

    def render
      super
    end
  end

  # Monkey patch hidden_field_tag to remove autocomplete="off"
  ActionView::Helpers::FormTagHelper.class_eval do
    remove_possible_method :hidden_field_tag

    def hidden_field_tag(name, value = nil, options = {})
      text_field_tag(name, value, options.merge(type: :hidden))
    end
  end

  # Monkey patch token_tag, method_tag, and button_to to remove autocomplete="off"
  ActionView::Helpers::UrlHelper.class_eval do # rubocop:disable Metrics/BlockLength
    BUTTON_TAG_METHOD_VERBS = %w[patch put delete] # rubocop:disable Lint/ConstantDefinitionInBlock,Style/MutableConstant
    remove_possible_method :token_tag

    def token_tag(token = nil, form_options: {})
      if token != false && defined?(protect_against_forgery?) && protect_against_forgery?
        if token == true || token.nil?
          token =
            form_authenticity_token(form_options: form_options.merge(authenticity_token: token))
        end
        tag(:input, type: 'hidden', name: request_forgery_protection_token.to_s, value: token)
      else
        ''
      end
    end

    remove_possible_method :method_tag

    def method_tag(method)
      tag('input', type: 'hidden', name: '_method', value: method.to_s)
    end

    remove_possible_method :button_to
    def button_to(name = nil, options = nil, html_options = nil, &block) # rubocop:disable Metrics
      if block_given?
        html_options = options
        options = name
      end
      html_options ||= {}
      html_options = html_options.stringify_keys

      url =
        case options
        when FalseClass then nil
        else url_for(options)
        end

      remote = html_options.delete('remote')
      params = html_options.delete('params')

      authenticity_token = html_options.delete('authenticity_token')

      method     = (html_options.delete('method').presence || method_for_options(options)).to_s
      method_tag = BUTTON_TAG_METHOD_VERBS.include?(method) ? method_tag(method) : ''.html_safe

      form_method  = method == 'get' ? 'get' : 'post'
      form_options = html_options.delete('form') || {}
      form_options[:class] ||= html_options.delete('form_class') || 'button_to'
      form_options[:method] = form_method
      form_options[:action] = url
      form_options[:'data-remote'] = true if remote

      request_token_tag = if form_method == 'post'
                            request_method = method.empty? ? 'post' : method
                            token_tag(authenticity_token, form_options: { action: url, method: request_method })
                          else
                            ''
                          end

      html_options = convert_options_to_data_attributes(options, html_options)
      html_options['type'] = 'submit'

      button = if block_given?
                 content_tag('button', html_options, &block)
               elsif button_to_generates_button_tag
                 content_tag('button', name || url, html_options, &block)
               else
                 html_options['value'] = name || url
                 tag('input', html_options)
               end

      inner_tags = method_tag.safe_concat(button).safe_concat(request_token_tag) # rubocop:disable Rails/OutputSafety
      if params
        to_form_params(params).each do |param|
          inner_tags.safe_concat tag(:input, type: 'hidden', name: param[:name], value: param[:value]) # rubocop:disable Rails/OutputSafety
        end
      end
      html = content_tag('form', inner_tags, form_options)
      prevent_content_exfiltration(html)
    end
  end
end
