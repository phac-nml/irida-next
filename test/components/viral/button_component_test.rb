# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class ButtonComponentTest < ViewComponentTestCase
    test 'basic button' do
      render_inline(Viral::ButtonComponent.new) do
        'Basic Button'
      end

      assert_selector 'button.button--state-default' do
        assert_text 'Basic Button'
      end
    end

    test 'destructive button' do
      render_inline(Viral::ButtonComponent.new(state: :destructive)) do
        'Destructive Button'
      end

      assert_selector 'button.button--state-destructive' do
        assert_text 'Destructive Button'
      end
    end

    test 'disclosure button default' do
      render_inline(Viral::ButtonComponent.new(disclosure: true)) do
        'Disclosure Button'
      end

      assert_selector 'button' do
        assert_text 'Disclosure Button'
        assert_selector 'svg.icon-chevron_down'
      end
    end

    test 'disclosure button down' do
      render_inline(Viral::ButtonComponent.new(disclosure: :down)) do
        'Disclosure Button'
      end

      assert_selector 'button' do
        assert_text 'Disclosure Button'
        assert_selector 'svg.icon-chevron_down'
      end
    end

    test 'disclosure button up' do
      render_inline(Viral::ButtonComponent.new(disclosure: :up)) do
        'Disclosure Button'
      end

      assert_selector 'button' do
        assert_text 'Disclosure Button'
        assert_selector 'svg.icon-chevron_up'
      end
    end

    test 'disclosure button right' do
      render_inline(Viral::ButtonComponent.new(disclosure: :right)) do
        'Disclosure Button'
      end

      assert_selector 'button' do
        assert_text 'Disclosure Button'
        assert_selector 'svg.icon-chevron_right'
      end
    end

    test 'button full width' do
      render_inline(Viral::ButtonComponent.new(full_width: true)) do
        'Full Width Button'
      end

      assert_selector 'button.w-full' do
        assert_text 'Full Width Button'
      end
    end

    test 'button large' do
      render_inline(Viral::ButtonComponent.new(size: :large)) do
        'Large Button'
      end

      assert_selector 'button.button--size-large' do
        assert_text 'Large Button'
      end
    end

    test 'button small' do
      render_inline(Viral::ButtonComponent.new(size: :small)) do
        'Small Button'
      end

      assert_selector 'button.button--size-default' do
        assert_text 'Small Button'
      end
    end
  end
end
