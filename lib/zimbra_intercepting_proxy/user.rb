module ZimbraInterceptingProxy

  class User
    attr_accessor :email, :zimbra_id, :mail_host

    @@db = {}

    def self.find(account)
      auth_token = ZimbraInterceptingProxy::Config.zimbra_admin_authtoken
      account = ZimbraInterceptingProxy::ZmLookup.find_zimbra_account(account: account, auth_token: auth_token)
      return account if account.nil?
      self.new account
    end

    # user_identifier can be an email address, zimbraId UUID or just the
    # local part of an email address, like user in user@example.com
    def initialize(zimbra_id: nil, email: nil, mail_host: nil)
      @zimbra_id = zimbra_id
      @email = email
      @mail_host = mail_host
      if mail_host =~ /:/
        @mail_host = mail_host.split(':')[1]
      end
    end

    def backend
      mailbox_ip = ZimbraInterceptingProxy::Backend.for_user(self)
      mailbox_hostname = mail_host
      mailbox_mapping = ZimbraInterceptingProxy::Config.mailboxes_mapping[mailbox_ip]
      return {
        host: mailbox_ip,
        host_name: mailbox_hostname,
        port: mailbox_mapping[:port],
        path: mailbox_mapping[:zimbra_url_path]
      }
    end
  end

end
