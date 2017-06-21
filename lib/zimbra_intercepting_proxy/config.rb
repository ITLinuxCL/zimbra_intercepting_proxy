module ZimbraInterceptingProxy
  module Config
    attr_accessor :new_backend, :old_backend

    ROUTE_URL = "/service/extension/nginx-lookup"
    ROUTE_REQUEST_PORT = 7072
    AUTH_REQUEST_PORT = 80

    def self.admin_user=(admin_user)
      @admin_user = admin_user
    end

    def self.admin_password=(admin_password)
      @admin_password = admin_password
    end

    def self.bind_address=(bind_address)
      @bind_address = bind_address || '0.0.0.0'
    end

    def self.bind_port=(bind_port)
      @bind_port = bind_port || '9090'
    end

    def self.debug=(debug)
      @debug = debug
    end

    def self.default_mailbox_ip=(mailbox_ip)
      @default_mailbox_ip = mailbox_ip
    end

    def self.mailboxes_webmail_port=(mailboxes_port = '')
      @mailboxes_webmail_port = {}
      mailboxes_port.split(';').each do |mbx_port|
        mailbox_ip, mailbox_port = mbx_port.split(':')
        @mailboxes_webmail_port[mailbox_ip] = mailbox_port
      end

    end

    def self.domain=(domain)
      @domain = domain
    end

    def self.mail_host_attribute=(mail_host_attribute)
      @mail_host_attribute = mail_host_attribute || 'zimbraMailTransport'
    end

    def self.mailboxes_webmail_port
      @mailboxes_webmail_port
    end

    def self.name_servers=(name_servers = [])
      @name_servers = name_servers
    end

    def self.old_mailbox_mail_url_path=(url_path)
      @old_mailbox_mail_url_path = url_path || '/'
    end

    def self.soap_admin_url=(url)
      @soap_admin_url = url
    end

    def self.zimbra_admin_authtoken=(token)
      @zimbra_admin_authtoken = token
    end

    def self.admin_user
      @admin_user
    end

    def self.admin_password
      @admin_password
    end

    def self.default_mailbox_ip
      @default_mailbox_ip
    end

    def self.domain
      @domain
    end

    def self.bind_port
      @bind_port
    end

    def self.bind_address
      @bind_address
    end

    def self.debug
      @debug
    end

    def self.mail_host_attribute
      @mail_host_attribute
    end

    def self.name_servers
      @name_servers || []
    end

    def self.old_mailbox_mail_url_path
      @old_mailbox_mail_url_path
    end

    def self.soap_admin_url
      @soap_admin_url
    end

    def self.zimbra_admin_authtoken
      @zimbra_admin_authtoken
    end
  end
end
