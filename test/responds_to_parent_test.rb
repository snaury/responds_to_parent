ENV["RAILS_ENV"] = "test"
require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test_help'

class IFrameController < ActionController::Base
  def normal
    render :update do |page| 
      page.alert "foo"
    end
  end
  
  def aliased
    respond_to_parent do
      render :text => 'woot'
    end
  end
  
  def redirect
    responds_to_parent do
      redirect_to '/another/place'
    end
  end
  
  def quotes
    responds_to_parent do
      render :text => %(single' double" qs\\' qd\\" escaped\\\' doubleescaped\\\\')
    end
  end
  
  def newlines
    responds_to_parent do
      render :text => "line1\nline2\\nline2"
    end
  end
  
  def update
    responds_to_parent do
      render :update do |page|
        page.alert 'foo'
        page.alert 'bar'
      end
    end
  end
  
  def rescue_action(e)
     raise e
  end
end

class RespondsToParentTest < ActionController::TestCase
  def setup
    @controller = IFrameController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_normal
    get :normal
    assert_match /alert\("foo"\)/, @response.body
    assert_no_match /parent_eval/, @response.body
  end
  
  def test_quotes_should_be_escaped
    render :quotes
    assert_match %r{parent_eval\('single\\' double\\" qs\\\\\\' qd\\\\\\" escaped\\\\\\' doubleescaped\\\\\\\\\\'}, @response.body
  end
  
  def test_newlines_should_be_escaped
    render :newlines
    assert_match %r{parent_eval\('line1\\nline2\\\\nline2'\)}, @response.body
  end
  
  def test_update_should_perform_combined_rjs
    render :update
    assert_match /alert\(\\"foo\\"\);\\nalert\(\\"bar\\"\)/, @response.body
  end
  
  def test_aliased_method_should_not_raise
    assert_nothing_raised do
      render :aliased
      assert_match /parent_eval\('woot'\)/, @response.body
    end
  end
  
protected
  
  def render(action)
    get action
    assert_match /<script type='text\/javascript'/, @response.body
    assert_match /parent_eval/, @response.body
    assert_match /document\.location\.replace\('about:blank'\)/, @response.body
  end
end
