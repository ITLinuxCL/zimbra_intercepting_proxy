module ZimbraInterceptingProxy
  module Backend
    require 'ipaddress'

    def self.for_user(user)
      return nil unless user.mail_host
      return user.mail_host if IPAddress.valid? user.mail_host
      begin
        ZimbraInterceptingProxy::Debug.logger "DNS:: Resolving IP for #{user.mail_host}"
        lookup = self.dns_client.getaddress(user.mail_host)
        backend_ip = lookup.to_s
        ZimbraInterceptingProxy::Debug.logger "DNS:: Found IP #{backend_ip} for #{user.mail_host}"
      rescue Resolv::ResolvError => e
        ZimbraInterceptingProxy::Debug.logger e.message
      end

      return backend_ip
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
