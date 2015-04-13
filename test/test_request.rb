require 'test_helper'

class Request < Minitest::Test
  
  def setup
    @auth_request = IO.read("./test/fixtures/auth_80.txt")
    @route_request = IO.read("./test/fixtures/route_7072.txt")
  end
  
  # def test_should_return_user_token_from_auth_request
  #   request = ZimbraInterceptingProxy::Request.new @auth_request
  #   assert_equal("pbruna", request.user_token)
  # end
  #
  # def test_should_return_user_token_from_route_request
  #   request = ZimbraInterceptingProxy::Request.new @route_request
  #   assert_equal("251b1902-2250-4477-bdd1-8a101f7e7e4e", request.user_token)
  # end
  #
end