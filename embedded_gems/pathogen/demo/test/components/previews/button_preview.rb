class ButtonPreview < Lookbook::Preview
  # @!group Basic

  # @label Default
  def default
    render Pathogen::Button.new do
      "Click me"
    end
  end
end
