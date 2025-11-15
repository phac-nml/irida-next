# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
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

      test 'applies default variant color classes' do
        render_inline(Heading.new(level: 2)) { 'Test' }

        assert_selector 'h2.text-slate-900.dark\\:text-white'
      end

      test 'applies muted variant color classes' do
        render_inline(Heading.new(level: 2, variant: :muted)) { 'Test' }

        assert_selector 'h2.text-slate-500.dark\\:text-slate-400'
      end

      test 'applies subdued variant color classes' do
        render_inline(Heading.new(level: 2, variant: :subdued)) { 'Test' }

        assert_selector 'h2.text-slate-700.dark\\:text-slate-300'
      end

      test 'applies inverse variant color classes' do
        render_inline(Heading.new(level: 2, variant: :inverse)) { 'Test' }

        assert_selector 'h2.text-white.dark\\:text-slate-900'
      end

      test 'applies sans font family' do
        render_inline(Heading.new(level: 1)) { 'Test' }

        assert_selector 'h1.font-sans'
      end

      test 'applies leading tight for better heading spacing' do
        render_inline(Heading.new(level: 1)) { 'Test' }

        assert_selector 'h1.leading-tight'
      end

      test 'applies tracking tight for h1 and h2' do
        render_inline(Heading.new(level: 1)) { 'H1' }
        assert_selector 'h1.tracking-tight'

        render_inline(Heading.new(level: 2)) { 'H2' }
        assert_selector 'h2.tracking-tight'
      end

      test 'applies tracking normal for h3-h6' do
        (3..6).each do |level|
          render_inline(Heading.new(level: level)) { 'Test' }

          assert_selector "h#{level}.tracking-normal"
        end
      end

      test 'merges custom classes with component classes' do
        render_inline(Heading.new(level: 1, class: 'custom-class mb-4')) { 'Test' }

        assert_selector 'h1.custom-class.mb-4.text-3xl'
      end

      test 'accepts additional HTML attributes' do
        render_inline(Heading.new(level: 1, id: 'main-heading', data: { controller: 'tooltip' })) { 'Test' }

        assert_selector 'h1#main-heading[data-controller="tooltip"]'
      end

      test 'raises error for invalid levels in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Heading.new(level: 0)
        end

        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Heading.new(level: 10)
        end
      end

      test 'raises error for invalid variant in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Heading.new(level: 1, variant: :invalid)
        end
      end

      test 'handles string level input by converting to integer' do
        render_inline(Heading.new(level: '2')) { 'Test' }

        assert_selector 'h2', text: 'Test'
      end

      test 'handles negative level by raising error in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Heading.new(level: -1)
        end
      end

      test 'handles non-numeric string level by raising error in development' do
        assert_raises(Pathogen::FetchOrFallbackHelper::InvalidValueError) do
          Heading.new(level: 'invalid')
        end
      end

      test 'responsive h1 uses correct mobile and desktop sizes' do
        render_inline(Heading.new(level: 1)) { 'Test' }

        # Mobile: 31px (text-3xl), Desktop: 49px (text-5xl)
        assert_selector 'h1.text-3xl.sm\\:text-5xl'
      end

      test 'responsive h2 uses correct mobile and desktop sizes' do
        render_inline(Heading.new(level: 2)) { 'Test' }

        # Mobile: 25px (text-2xl), Desktop: 39px (text-4xl)
        assert_selector 'h2.text-2xl.sm\\:text-4xl'
      end

      test 'non-responsive heading uses mobile size only' do
        render_inline(Heading.new(level: 3, responsive: false)) { 'Test' }

        # Non-responsive headings use mobile size (no breakpoint modifiers)
        assert_selector 'h3.text-xl'
        assert_no_selector 'h3.sm\\:text-3xl'
      end
    end
  end
end
