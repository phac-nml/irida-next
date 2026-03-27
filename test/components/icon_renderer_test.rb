# frozen_string_literal: true

require 'test_helper'

class IconRendererTest < ActiveSupport::TestCase
  test 'build_options includes variant and library without mutating source options' do
    source_options = { class: 'custom-class' }

    options = IconRenderer.build_options(:fill, :heroicons, source_options)

    assert_equal({ class: 'custom-class', variant: :fill, library: :heroicons }, options)
    assert_equal({ class: 'custom-class' }, source_options)
  end

  test 'build_options skips nil variant and library' do
    options = IconRenderer.build_options(nil, nil, { class: 'custom-class' })

    assert_equal({ class: 'custom-class' }, options)
  end

  test 'apply_styling adds fill-current class for fill variant' do
    options = {}

    IconRenderer.apply_styling(options, :primary, :md, :fill)

    assert_includes options[:class], 'fill-current'
    assert_includes options[:class], 'text-primary-600'
    assert_includes options[:class], 'size-6'
  end

  test 'append_icon_name_class is a no-op when icon name is blank' do
    options = { class: 'custom-class' }

    IconRenderer.append_icon_name_class(options, nil)
    IconRenderer.append_icon_name_class(options, '')

    assert_equal 'custom-class', options[:class]
  end

  test 'clean_html returns non-string values unchanged' do
    payload = { ok: true }

    assert_same payload, IconRenderer.clean_html(payload)
  end

  test 'clean_html removes data attribute using nokogiri sanitizer' do
    cleaned = IconRenderer.clean_html('<svg class="custom-icon" data=""></svg>')

    assert_not_includes cleaned.to_s, 'data='
    assert_includes cleaned.to_s, 'class="custom-icon"'
  end

  test 'clean_html falls back to regex sanitizer if nokogiri parsing fails' do
    original_parse = Nokogiri::HTML::DocumentFragment.method(:parse)
    Nokogiri::HTML::DocumentFragment.singleton_class.send(:define_method, :parse) do |_html|
      raise StandardError, 'parse failure'
    end

    begin
      cleaned = IconRenderer.clean_html('<svg class="fallback-icon" data="bad"></svg>')

      assert_not_includes cleaned.to_s, 'data='
      assert_includes cleaned.to_s, 'class="fallback-icon"'
    ensure
      Nokogiri::HTML::DocumentFragment.singleton_class.send(:define_method, :parse) do |*args, **kwargs, &block|
        original_parse.call(*args, **kwargs, &block)
      end
    end
  end
end
