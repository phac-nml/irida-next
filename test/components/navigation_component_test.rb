# frozen_string_literal: true

require 'test_helper'

class NavigationComponentTest < ViewComponent::TestCase
  test 'should render navigation for projects page' do
    with_request_url '/-/projects' do
      render_inline Navigation::NavigationComponent.new do |navigation|
        navigation.with_header(label: 'Home', url: '/', icon: 'home')
        navigation.with_section do |section|
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups', icon: 'cog_6_tooth')
        end
      end

      assert_selector 'aside' do
        assert_text 'Home'
        assert_selector 'ul' do
          assert_selector 'li', count: 2
          assert_selector 'a.bg-gray-100[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end

      assert_selector 'button[data-action="click->layout#toggle"]' do
        assert_selector 'svg.w-6.h-6'
      end
    end
  end

  test 'should render navigation for groups page' do
    with_request_url '/-/groups' do
      render_inline Navigation::NavigationComponent.new do |navigation|
        navigation.with_header(label: 'Home', url: '/', icon: 'home')
        navigation.with_section do |section|
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups', icon: 'cog_6_tooth')
        end
      end

      assert_selector 'aside' do
        assert_text 'Home'
        assert_selector 'ul' do
          assert_selector 'li', count: 2
          assert_selector 'a[href="/-/projects"]'
          assert_no_selector 'a.bg-gray-100[href="/-/projects"]'
          assert_selector 'a.bg-gray-100[href="/-/groups"]'
        end
      end

      assert_selector 'button[data-action="click->layout#toggle"]' do
        assert_selector 'svg.w-6.h-6'
      end
    end
  end

  test 'section component should render with a title' do
    with_request_url '/-/projects' do
      render_inline Navigation::NavigationComponent.new do |navigation|
        navigation.with_header(label: 'Home', url: '/', icon: 'home')
        navigation.with_section(title: 'Good Section') do |section|
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups', icon: 'cog_6_tooth')
        end
      end

      assert_selector 'aside' do
        assert_text 'Good Section'
      end
    end
  end

  test 'render componet without section block' do
    with_request_url '/-/projects' do
      render_inline Navigation::NavigationComponent.new do |navigation|
        navigation.with_header(label: 'Home', url: '/', icon: 'home')
        navigation.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
        navigation.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups', icon: 'cog_6_tooth')
      end

      assert_selector 'aside' do
        assert_text 'Home'
        assert_selector 'ul' do
          assert_selector 'li', count: 2
          assert_selector 'a.bg-gray-100[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end
    end
  end

  test 'render componet with header block' do
    with_request_url '/-/projects' do
      render_inline Navigation::NavigationComponent.new do |navigation|
        navigation.with_section do |section|
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/projects', icon: 'home')
          section.with_item(label: I18n.t(:'general.default_sidebar.projects'), url: '/-/groups', icon: 'cog_6_tooth')
        end
      end

      assert_selector 'aside' do
        assert_selector 'ul' do
          assert_selector 'li', count: 2
          assert_selector 'a.bg-gray-100[href="/-/projects"]'
          assert_selector 'a[href="/-/groups"]'
        end
      end
    end
  end
end
