# frozen_string_literal: true

class ViralAlertComponentPreview < ViewComponent::Preview
  # 🚨 ALERT TYPES - Different styles for different purposes

  def info_alert
    # ℹ️  Default alert type - perfect for general information
    # Use this for updates, tips, or general notifications
  end

  def success_alert
    # ✅ Success alerts - celebrate achievements and confirmations
    # Use this for successful operations, completed tasks, or positive feedback
  end

  def warning_alert
    # ⚠️  Warning alerts - draw attention to potential issues
    # Use this for important notices, recommendations, or cautionary messages
  end

  def danger_alert
    # 🚨 Danger alerts - critical information that needs immediate attention
    # Use this for errors, failures, or critical warnings
  end

  # 🎯 INTERACTIVE FEATURES - User control and automation

  def dismissible_alert
    # 🚪 Dismissible alerts - users can close them manually
    # Perfect for important messages that users should acknowledge
  end

  def auto_dismiss_alert
    # ⏰ Auto-dismiss alerts - disappear automatically after 5 seconds
    # Great for temporary notifications that don't require user action
  end

  def dismissible_with_auto_dismiss
    # 🎭 Best of both worlds - users can close manually OR wait for auto-dismiss
    # Ideal for important but not critical messages
  end

  # 📝 CONTENT VARIATIONS - Different ways to present information

  def simple_message
    # 💬 Simple text message - clean and straightforward
    # Perfect for short notifications or status updates
  end

  def with_rich_content
    # 📚 Rich content alerts - include additional information or actions
    # Great for complex messages that need more context
  end

  def with_actions
    # 🔘 Action buttons - include interactive elements within the alert
    # Perfect for alerts that require user decisions or actions
  end

  # 🎨 ADVANCED USAGE - Complex scenarios and combinations

  def long_message_alert
    # 📖 Long message alerts - handle extensive content gracefully
    # Shows how the component adapts to different content lengths
  end

  def multiple_alerts
    # 🎪 Multiple alerts - demonstrate how multiple alerts work together
    # Shows spacing, stacking, and interaction between alerts
  end

  def custom_styling
    # 🎨 Custom styling - demonstrate how to override default styles
    # Shows the flexibility of the component system
  end

  # 🔧 ACCESSIBILITY FEATURES - Screen reader and keyboard support

  def accessibility_demo
    # ♿ Accessibility demonstration - showcase screen reader support
    # Shows ARIA attributes, keyboard navigation, and focus management
  end

  # 📱 RESPONSIVE BEHAVIOR - How alerts adapt to different screen sizes

  def responsive_demo
    # 📱 Responsive behavior - demonstrate mobile and desktop adaptations
    # Shows how alerts look and behave on different devices
  end
end
