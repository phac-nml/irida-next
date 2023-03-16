require "application_system_test_case"

class SamplesTest < ApplicationSystemTestCase
  setup do
    @sample = samples(:one)
  end

  test "visiting the index" do
    visit samples_url
    assert_selector "h1", text: "Samples"
  end

  test "should create sample" do
    visit samples_url
    click_on "New sample"

    fill_in "Description", with: @sample.description
    fill_in "Name", with: @sample.name
    fill_in "Project", with: @sample.project_id
    click_on "Create Sample"

    assert_text "Sample was successfully created"
    click_on "Back"
  end

  test "should update Sample" do
    visit sample_url(@sample)
    click_on "Edit this sample", match: :first

    fill_in "Description", with: @sample.description
    fill_in "Name", with: @sample.name
    fill_in "Project", with: @sample.project_id
    click_on "Update Sample"

    assert_text "Sample was successfully updated"
    click_on "Back"
  end

  test "should destroy Sample" do
    visit sample_url(@sample)
    click_on "Destroy this sample", match: :first

    assert_text "Sample was successfully destroyed"
  end
end
