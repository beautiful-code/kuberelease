require 'test_helper'

class EnvironmentsControllerTest < ActionController::TestCase
  setup do
    @environment = environments(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:environments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create environment" do
    assert_difference('Environment.count') do
      post :create, environment: { k8s_master: @environment.k8s_master, k8s_password: @environment.k8s_password, k8s_username: @environment.k8s_username, name: @environment.name, suite_id: @environment.suite_id }
    end

    assert_redirected_to environment_path(assigns(:environment))
  end

  test "should show environment" do
    get :show, id: @environment
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @environment
    assert_response :success
  end

  test "should update environment" do
    patch :update, id: @environment, environment: { k8s_master: @environment.k8s_master, k8s_password: @environment.k8s_password, k8s_username: @environment.k8s_username, name: @environment.name, suite_id: @environment.suite_id }
    assert_redirected_to environment_path(assigns(:environment))
  end

  test "should destroy environment" do
    assert_difference('Environment.count', -1) do
      delete :destroy, id: @environment
    end

    assert_redirected_to environments_path
  end
end
