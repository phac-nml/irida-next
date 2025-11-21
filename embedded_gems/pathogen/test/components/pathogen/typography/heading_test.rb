# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    # Test suite for Heading component
    class HeadingTest < ViewComponent::TestCase
      test 'renders h1 with correct semantic HTML' do
        render_inline(Heading.new(level: 1)) { 'Test Heading' }

        assert_selector 'h1', text: 'Test Heading'
      end

      test 'renders all heading levels correctly' do
        (1..6).each do |level|
          render_inline(Heading.new(level: level)) { "Heading #{level}" }

          assert_selector "h#{level}", text: "Heading #{level}"
        end
      end

      test 'applies responsive sizing classes by default' do
        render_inline(Heading.new(level: 1)) { 'Test' }

        assert_selector 'h1.text-3xl.sm\\:text-5xl'
      end

      test 'applies fixed sizing when responsive is false' do
        render_inline(Heading.new(level: 1, responsive: false)) { 'Test' }

        assert_selector 'h1.text-3xl'
        assert_no_selector 'h1.sm\\:text-5xl'
      end

      test 'applies variant color classes' do
        render_inline(Heading.new(level: 2)) { 'Test' }
        assert_selector 'h2.text-slate-900.dark\\:text-white'

        render_inline(Heading.new(level: 2, variant: :muted)) { 'Test' }
        assert_selector 'h2.text-slate-500.dark\\:text-slate-400'

        render_inline(Heading.new(level: 2, variant: :subdued)) { 'Test' }
        assert_selector 'h2.text-slate-700.dark\\:text-slate-300'

        render_inline(Heading.new(level: 2, variant: :inverse)) { 'Test' }
        assert_selector 'h2.text-white.dark\\:text-slate-900'
      end

      test 'applies typography classes' do
        render_inline(Heading.new(level: 1)) { 'Test' }
        assert_selector 'h1.font-sans.leading-tight.tracking-tight'

        render_inline(Heading.new(level: 3)) { 'Test' }
        assert_selector 'h3.tracking-normal'
      end

      test 'merges custom classes with component classes' do
        render_inline(Heading.new(level: 1, class: 'custom-class mb-4')) { 'Test' }

        assert_selector 'h1.custom-class.mb-4.text-3xl'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Heading.new(level: 1, id: 'main-heading', data: { controller: 'tooltip' })) { 'Test' }

        assert_selector 'h1#main-heading[data-controller="tooltip"]'
      end

      test 'validates level and variant inputs' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) { Heading.new(level: 0) }
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) { Heading.new(level: 10) }
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) { Heading.new(level: -1) }
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) { Heading.new(level: 'invalid') }
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) { Heading.new(level: 1, variant: :invalid) }

        render_inline(Heading.new(level: '2')) { 'Test' }
        assert_selector 'h2', text: 'Test'
      end

      test 'applies responsive sizing correctly' do
        render_inline(Heading.new(level: 1)) { 'Test' }
        assert_selector 'h1.text-3xl.sm\\:text-5xl'

        render_inline(Heading.new(level: 2)) { 'Test' }
        assert_selector 'h2.text-2xl.sm\\:text-4xl'

        render_inline(Heading.new(level: 3, responsive: false)) { 'Test' }
        assert_selector 'h3.text-xl'
        assert_no_selector 'h3.sm\\:text-3xl'
      end
    end
  end
end
