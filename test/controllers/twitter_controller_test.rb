require 'test_helper'

class TwitterControllerTest < ActionController::TestCase
  test "should get view_chart" do
    get :view_chart
    assert_response :success
  end

end
