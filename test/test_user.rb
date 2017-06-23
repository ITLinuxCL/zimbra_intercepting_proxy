require 'test_helper'

class TestUser < Minitest::Test

  def setup
    @user = {
      email: "watson@example.com",
      zimbra_id: "251b1902-2250-4477-bdd1-8a101f7e7e4e",
      mail_host: "zimbra8.zboxapp.dev"
    }
    ZmProxy::Config.zimbra_admin_authtoken = "11111"
  end

  def before_each
    ZmProxy::Config.mail_host_attribute = 'zimbraMailHost'
  end

  def after_each
    ZmProxy::Config.mail_host_attribute = 'zimbraMailHost'
  end

  def test_find_should_work_with_email
    ZmProxy::Config.mail_host_attribute = 'zimbraMailTransport'
    account_email = "user@example.com"
    account_id = "cfd6e914-4f00-440c-9a57-e1a9327128b9"
    account_mailhost = "lmtp:server-05.zboxapp.dev:7025"
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
                  \"_content\":\"#{account_mailhost}\"
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

    user = ZmProxy::User.find(account_email)
    assert_equal(account_id, user.zimbra_id)
    assert_equal(account_mailhost.split(':')[1], user.mail_host)
  end

  def test_find_should_work_with_id
    account_email = "admin@zboxapp.dev"
    account_id = "cfd6e914-4f00-440c-9a57-e1a9327128b9"
    account_mailhost = "server-05.zboxapp.dev"
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
                  \"n\":\"zimbraMailHost\",
                  \"_content\":\"#{account_mailhost}\"
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

    user = ZmProxy::User.find(account_id)
    assert_equal(account_email, user.email)
    assert_equal(account_mailhost, user.mail_host)
  end

  def test_find_should_throw_user_not_found
    fixture_response = "
    {
      \"Header\":{
        \"context\":{
          \"_jsns\":\"urn:zimbra\"
        }
      },
      \"Body\":{
        \"Fault\":{}
      },
      \"_jsns\":\"urn:zimbraSoap\"
    }
    "
    stub_request(:post, /service\/admin\/soap$/).
      with(body: /GetAccountRequest/).
      to_return(body: fixture_response)

    r = ZmProxy::ZmLookup.find_zimbra_account(account: 'chupa@zboxapp.dev', auth_token: "auth_token")
    assert_nil(r)
  end

end
