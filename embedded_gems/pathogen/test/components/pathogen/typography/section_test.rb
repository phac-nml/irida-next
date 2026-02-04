# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Typography
    # Test suite for Section component
    class SectionTest < ViewComponent::TestCase
      test 'renders section with heading and content' do
        render_inline(Section.new(level: 2)) do |section|
          section.with_heading { 'Section Title' }
          'Section content'
        end

        assert_selector 'section'
        assert_selector 'h2', text: 'Section Title'
        assert_text 'Section content'
      end

      test 'renders with default spacing' do
        render_inline(Section.new(level: 2)) do |section|
          section.with_heading { 'Title' }
        end

        assert_selector 'section.space-y-4'
      end

      test 'renders with compact spacing' do
        render_inline(Section.new(level: 3, spacing: :compact)) do |section|
          section.with_heading { 'Title' }
        end

        assert_selector 'section.space-y-2'
      end

      test 'renders with spacious spacing' do
        render_inline(Section.new(level: 2, spacing: :spacious)) do |section|
          section.with_heading { 'Title' }
        end

        assert_selector 'section.space-y-6'
      end

      test 'adds region role for h2 sections' do
        render_inline(Section.new(level: 2)) do |section|
          section.with_heading { 'Main Section' }
        end

        assert_selector 'section[role="region"]'
      end

      test 'does not add region role for other levels' do
        render_inline(Section.new(level: 3)) do |section|
          section.with_heading { 'Subsection' }
        end

        assert_no_selector 'section[role="region"]'
      end

      test 'accepts custom classes' do
        render_inline(Section.new(level: 2, class: 'custom-class')) do |section|
          section.with_heading { 'Title' }
        end

        assert_selector 'section.custom-class'
      end

      test 'derives heading id from wrapper id for aria-labelledby' do
        render_inline(Section.new(level: 2, id: 'overview')) do |section|
          section.with_heading { 'Overview' }
        end

        assert_selector 'section#overview[aria-labelledby="overview-heading"]'
        assert_selector 'h2#overview-heading', text: 'Overview'
      end

      test 'accepts explicit heading_id' do
        render_inline(Section.new(level: 2, heading_id: 'custom-heading')) do |section|
          section.with_heading { 'Custom Heading' }
        end

        assert_selector 'section[aria-labelledby="custom-heading"]'
        assert_selector 'h2#custom-heading', text: 'Custom Heading'
      end

      test 'passes heading attributes to Heading component' do
        render_inline(Section.new(level: 3)) do |section|
          section.with_heading(variant: :muted) { 'Muted Title' }
        end

        assert_selector 'h3.text-slate-500', text: 'Muted Title'
      end

      test 'renders without heading' do
        render_inline(Section.new(level: 2)) do
          'Only content'
        end

        assert_no_selector 'h2'
        assert_text 'Only content'
      end

      test 'renders without content' do
        render_inline(Section.new(level: 2)) do |section|
          section.with_heading { 'Only heading' }
        end

        assert_selector 'h2', text: 'Only heading'
      end

      test 'does not validate hierarchy in test environment by default' do
        # Should not raise or warn in test env
        render_inline(Section.new(level: 4, parent_level: 1, validate: false)) do |section|
          section.with_heading { 'Skip levels' }
        end

        assert_selector 'h4'
      end

      test 'allows same level as parent (sibling sections)' do
        # Should not raise when same level as parent
        render_inline(Section.new(level: 2, parent_level: 2, validate: true)) do |section|
          section.with_heading { 'Sibling section' }
        end

        assert_selector 'h2', text: 'Sibling section'
      end

      test 'normalizes string level to integer' do
        render_inline(Section.new(level: '2')) do |section|
          section.with_heading { 'String Level' }
        end

        assert_selector 'section[role="region"]'
        assert_selector 'h2', text: 'String Level'
      end

      test 'normalizes string parent_level for hierarchy validation' do
        # Should not warn when string parent_level is normalized correctly
        render_inline(Section.new(level: 3, parent_level: '2', validate: true)) do |section|
          section.with_heading { 'Child section' }
        end

        assert_selector 'h3', text: 'Child section'
      end

      test 'normalizes both level and parent_level as strings' do
        render_inline(Section.new(level: '3', parent_level: '2', validate: true)) do |section|
          section.with_heading { 'Both normalized' }
        end

        assert_selector 'h3', text: 'Both normalized'
      end
    end
  end
end
