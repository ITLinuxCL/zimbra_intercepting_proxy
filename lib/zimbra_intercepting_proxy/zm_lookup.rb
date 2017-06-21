module ZimbraInterceptingProxy

  module ZmLookup
    require 'rest-client'

    def self.build_json_auth(username, password)
      request = { Body: { AuthRequest: { } } }
      request[:Body][:AuthRequest] = {
        'account': { 'by': 'name', '_content': username },
        'password': password
        }
      request[:Body][:_jsns] = 'urn:zimbraAdmin'
      request.to_json
    end

    def self.build_json_get_account(account, authToken, mail_host_attribute)
      by = account !~ /@/ ? 'id' : 'name'
      request = { }
      request[:Header] = { context: { } }
      request[:Header][:context][:_jsns] = "urn:zimbra"
      request[:Header][:context][:authToken] = {
        _content: authToken
      }
      request[:Body] = { GetAccountRequest: { } }
      request[:Body][:GetAccountRequest][:attrs] = mail_host_attribute
      request[:Body][:GetAccountRequest][:account] = {
        by: by,  '_content': account
      }

      request[:Body][:GetAccountRequest][:_jsns] = 'urn:zimbraAdmin'
      request.to_json
    end

    def self.find_zimbra_account(account: nil, auth_token: nil)
      raise "account missing for ZmLookup" if account.nil?
      raise "auth_token missing for ZmLookup" if auth_token.nil?
      mail_host_attribute = ZimbraInterceptingProxy::Config.mail_host_attribute
      json_request = self.build_json_get_account(account, auth_token, mail_host_attribute)
      response = self.post_request(json_request)
      account_data = nil

      begin
        if response["Body"]["Fault"]
          Debug.logger "ZmLookup.find_zimbra_account: Account Not Found #{response["Body"]["Fault"]}"
          return account_data
        end
        data = response["Body"]["GetAccountResponse"]["account"].first
        account_data = {
          email: data["name"],
          zimbra_id: data["id"],
          mail_host: data["a"].first["_content"],
        }
      rescue Exception => e
        ZimbraInterceptingProxy::Debug.logger "ZmLookup.find_zimbra_account: #{e.message}"
      end

      return account_data
    end

    def self.login(username: nil, password: nil)
      raise "username missing for ZmLookup" if username.nil?
      raise "password missing for ZmLookup" if password.nil?
      auth_token = false
      json_request = self.build_json_auth(username, password)
      response = self.post_request(json_request)

      begin
        if response["Body"]["Fault"]
          Debug.logger response["Body"]["Fault"]
        end
        auth_token = response['Body']['AuthResponse']['authToken'].first['_content']

      rescue Exception => e
        ZimbraInterceptingProxy::Debug.logger e.message
      end

      ZimbraInterceptingProxy::Config::zimbra_admin_authtoken = auth_token
      return auth_token
    end

    def self.post_request(json_request)
      soap_admin_url = ZimbraInterceptingProxy::Config.soap_admin_url
      resource = RestClient::Resource.new(soap_admin_url, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
      begin
        response = resource.post json_request
        response_as_data = JSON.parse(response.body)
        return response_as_data
      rescue RestClient::ExceptionWithResponse => e
        response = e.response
        ZimbraInterceptingProxy::Debug.logger e.response.body
        return JSON.parse(e.response.body)
      end
    end

    def self.soap_admin_url
      return ZimbraInterceptingProxy::Config.soap_admin_url
    end

  end
end
