module ZimbraInterceptingProxy
  module Backend
    require 'ipaddress'
    require 'date'

    HOSTS_TTL_SECS = 3600
    @@hosts = {}

    def self.for_user(user)
      backend_ip = self.find_ipaddress(user)
      return backend_ip
    end

    def self.find_ipaddress(user)
      mail_host = user.mail_host || ZimbraInterceptingProxy::Config.default_mailbox_ip
      return mail_host if IPAddress.valid? mail_host
      record = @@hosts[mail_host]
      time_now = DateTime.now.to_time.to_i
      return record[:ipaddress] if (record && (time_now - record[:ttl]) < HOSTS_TTL_SECS )

      begin
        lookup = self.dns_client.getaddress(mail_host)
        backend_ip = lookup.to_s
        ZimbraInterceptingProxy::Debug.logger [:dns, "Found IP #{backend_ip} for #{user.mail_host}"]
      rescue Resolv::ResolvError => e
        ZimbraInterceptingProxy::Debug.logger e.message
      end
      @@hosts[mail_host] = { ipaddress: backend_ip, ttl: time_now }
      backend_ip
    end

    def self.dns_client
      name_servers = ZimbraInterceptingProxy::Config.name_servers
      name_servers = name_servers.kind_of?(Array) ? name_servers : name_servers.to_s.split(',')

      ZimbraInterceptingProxy::Debug.logger "DNS:: Using nameservers: #{name_servers.join(', ')}"

      domain = ZimbraInterceptingProxy::Config.domain

      if !name_servers.empty? && domain
        return Resolv::DNS.new(nameserver: name_servers, search: [domain], ndots: 1)
      else
        return Resolv::DNS.new()
      end
    end

  end
end
