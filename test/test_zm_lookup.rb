require 'test_helper'

class ZmLookup < Minitest::Test

  def setup
    @user_zm6_email = "zm6@zboxapp.dev"
    @user_zm8_email = "zm6@zboxapp.dev"
    @auth_token = "948493938"
  end

  def ZmLookup
    return ZimbraInterceptingProxy::ZmLookup
  end

  def test_should_return_admin_soap_url
    soap_admin_url = ZimbraInterceptingProxy::Config.soap_admin_url
    assert_equal(soap_admin_url, ZimbraInterceptingProxy::ZmLookup.soap_admin_url)
  end

  def test_should_return_formated_json_auth_request
    expected_json = '
      {
        "Body":{
          "AuthRequest": {
            "account": {
              "by": "name",
              "_content": "user@example.com"
            },
            "password": "password"
          },
          "_jsns": "urn:zimbraAdmin"
       }
     }
    '

    json_auth = ZimbraInterceptingProxy::ZmLookup.build_json_auth("user@example.com", "password")
    assert_equal(JSON.parse(expected_json), JSON.parse(json_auth))
  end

  def test_should_login
    fixture_response = "{\"Header\":{\"context\":{\"_jsns\":\"urn:zimbra\"}},\"Body\":{\"AuthResponse\":{\"authToken\":[{\"_content\":\"#{@auth_token}\"}],\"lifetime\":86399999,\"_jsns\":\"urn:zimbraAdmin\"}},\"_jsns\":\"urn:zimbraSoap\"}"
    stub_request(:post, /service\/admin\/soap$/).
      with(body: /AuthRequest/).
      to_return(body: fixture_response)

    ZimbraInterceptingProxy::ZmLookup.login(username: "user@example.com", password: "password")
    assert_equal(@auth_token, ZimbraInterceptingProxy::Config.zimbra_admin_authtoken)
  end

  def test_should_return_formated_json_get_account_request
    account_email = "user@example.com"
    expected_json = "
     {
       \"Header\": {
         \"context\": {
           \"_jsns\": \"urn:zimbra\",
           \"authToken\": {
             \"_content\": \"#{@auth_token}\"
           }
         }
       },
       \"Body\": {
         \"GetAccountRequest\": {
           \"attrs\": \"zimbraMailHost,zimbraMailTransport\",
           \"account\":{
             \"by\": \"name\",
             \"_content\": \"#{account_email}\"
           },
           \"_jsns\": \"urn:zimbraAdmin\"
         }
       }
     }
    "

    json_account = ZimbraInterceptingProxy::ZmLookup.build_json_get_account(
      "user@example.com", @auth_token, ["zimbraMailHost", "zimbraMailTransport"]
    )
    assert_equal(JSON.parse(expected_json), JSON.parse(json_account))
  end

  def test_should_return_account_info
    account_email = "user@example.com"
    account_id = "cfd6e914-4f00-440c-9a57-e1a9327128b9"
    account_transport = "lmtp:server-05.zboxapp.dev:7025"
    fixture_response = "
    {
      \"Header\":{
        \"context\":{
          \"_jsns\":\"urn:zimbra\"
        }
      },
      \"Body\":{
        \"GetAccountResponse\":{
          \"account\":[
            {
              \"name\":\"#{account_email}\",
              \"id\":\"#{account_id}\",
              \"a\":[
                {
                  \"n\":\"zimbraMailTransport\",
                  \"_content\":\"#{account_transport}\"
                }
              ]
            }
          ],
          \"_jsns\":\"urn:zimbraAdmin\"
        }
      },
      \"_jsns\":\"urn:zimbraSoap\"
    }
    "

    stub_request(:post, /service\/admin\/soap$/).
      with(body: /GetAccountRequest/).
      to_return(body: fixture_response)

    request_data = { account: "user@example.com", auth_token: "token", attrs: ['zimbraMailTransport']}

    response = ZimbraInterceptingProxy::ZmLookup.get_zimbra_account(request_data)
    assert_equal(account_transport, response["a"].first["_content"])
  end

  # def test_only_set_zimbraId_when_passed_a_zimbraId
  #   u = ZimbraInterceptingProxy::User.new(@user[:zimbraId])
  #   assert_equal(u.zimbraId, @user[:zimbraId])
  #   assert_nil(u.email)
  # end
  #
  # def test_only_set_email_when_passed_an_email
  #   u = ZimbraInterceptingProxy::User.new(@user[:email])
  #   assert_equal(u.email, @user[:email])
  #   assert_nil(u.zimbraId)
  # end
end
