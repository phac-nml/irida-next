# frozen_string_literal: true

# 🎨 Preview component for Pathogen::Button
#
# This preview provides various examples and configurations of the Pathogen button component.
# It demonstrates different styles, sizes, states, and visual elements.
class PathogenButtonPreview < ViewComponent::Preview
  # 🎮 Interactive Playground
  #
  # @param scheme select { choices: [default, primary, danger] } "Color scheme for visual styling"
  # @param size select { choices: [sm, base, lg] } "Button size variant"
  # @param disabled toggle "Makes the button non-interactive and visually muted"
  # @param block toggle "Makes the button expand to full container width"
  def playground(scheme: :default, size: :base, disabled: false, block: false)
    render Pathogen::Button.new(scheme:, size:, disabled:, block:, test_selector: 'playground') do
      'Button'
    end
  end

  # 📏 Size Variants
  #
  # Demonstrates all available button sizes from extra small to extra large.
  def sizes; end

  # ⚪ Default Button
  #
  # Standard button with neutral styling.
  #
  # @param disabled toggle "Makes the button non-interactive and visually muted"
  def default(disabled: false)
    render Pathogen::Button.new(disabled:, test_selector: 'default') do
      'Button'
    end
  end

  # 🔵 Primary Button
  #
  # Primary action button with prominent styling.
  #
  # @param disabled toggle "Makes the button non-interactive and visually muted"
  # @param block toggle "Makes the button expand to full container width"
  def primary(disabled: false, block: false)
    render Pathogen::Button.new(scheme: :primary, disabled:, block:, test_selector: 'primary') do
      'Button'
    end
  end

  # 🔴 Danger Button
  #
  # Destructive action button with warning styling.
  #
  # @param disabled toggle "Makes the button non-interactive and visually muted"
  # @param block toggle "Makes the button expand to full container width"
  def danger(disabled: false, block: false)
    render Pathogen::Button.new(scheme: :danger, disabled:, block:, test_selector: 'danger') do
      'Button'
    end
  end

  # 🎨 Color Schemes
  #
  # Shows all available button color schemes side by side.
  def all_schemes; end

  # ↔️ Full Width Button
  #
  # Demonstrates a button that spans the full width of its container.
  def full_width
    render Pathogen::Button.new(block: true, test_selector: 'full-width') do
      'Button'
    end
  end

  # 🔗 Link Button
  #
  # Button that functions as a link to external or internal resources.
  #
  # @param scheme select { choices: [default,primary, danger] } "Color scheme for visual styling"
  # @param href text "URL or path to link to"
  # @param disabled toggle "Makes the button non-interactive and visually muted"
  def link_as_a_button(scheme: :default, href: '#', disabled: false)
    render Pathogen::Button.new(scheme:, href:, tag: :a, disabled:, test_selector: 'link-as-a-button') do
      'Button'
    end
  end

  # 📈 Visual Elements
  #
  # Demonstrates buttons with leading and trailing visual elements.
  #
  # @param scheme select { choices: [default,primary, danger] } "Color scheme for visual styling"
  # @param size select { choices: [sm, base, lg] } "Button size variant"
  def leading_visual(scheme: :primary, size: :base)
    render_with_template(locals: {
                           scheme:,
                           size:
                         })
  end

  # 📈 Visual Elements
  #
  # Demonstrates buttons with leading and trailing visual elements.
  #
  # @param scheme select { choices: [default,primary, danger] } "Color scheme for visual styling"
  # @param size select { choices: [sm, base, lg] } "Button size variant"
  def leading_visual_svg(scheme: :primary, size: :base)
    render_with_template(locals: {
                           scheme:,
                           size:
                         })
  end

  # 📈 Visual Elements
  #
  # Demonstrates buttons with leading and trailing visual elements.
  #
  # @param scheme select { choices: [default,primary, danger] } "Color scheme for visual styling"
  # @param size select { choices: [sm, base, lg] } "Button size variant"
  def trailing_visual(scheme: :primary, size: :base)
    render_with_template(locals: {
                           scheme:,
                           size:
                         })
  end

  # 📈 Visual Elements
  #
  # Demonstrates buttons with leading and trailing visual elements.
  #
  # @param scheme select { choices: [default,primary, danger] } "Color scheme for visual styling"
  # @param size select { choices: [sm, base, lg] } "Button size variant"
  def trailing_visual_svg(scheme: :primary, size: :base)
    render_with_template(locals: {
                           scheme:,
                           size:
                         })
  end
end
