require 'test_helper'

class Backend < Minitest::Test

  def setup
    zimbra6_user_data = {
      zimbra_id: "251b1902-2250-4477-bdd1-8a101f7e7e4e",
      email: "zimbra6@zboxapp.dev",
      mail_host: "lmtp:zimbra6.zboxapp.dev:7025"
    }
    zimbra8_user_data = {
      zimbra_id: "251b1902-2250-4477-bdd1-8a101f7e7e4f",
      email: "zimbra8@zboxapp.dev",
      mail_host: "zimbra8.zboxapp.dev"
    }
    @zimbra6_user = ZimbraInterceptingProxy::User.new(zimbra6_user_data)
    @zimbra8_user = ZimbraInterceptingProxy::User.new(zimbra8_user_data)
    @ip_zimbra8 = "192.168.80.81"
    @ip_zimbra6 = "192.168.80.61"
  end

  def test_should_return_correct_ip_for_backend
    backend6 = ZimbraInterceptingProxy::Backend.for_user @zimbra6_user
    assert_equal(@ip_zimbra6, backend6)
    backend8 = ZimbraInterceptingProxy::Backend.for_user @zimbra8_user
    assert_equal(@ip_zimbra8, backend8)
  end
end
