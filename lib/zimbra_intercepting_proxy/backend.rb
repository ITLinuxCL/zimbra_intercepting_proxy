module ZimbraInterceptingProxy
  module Backend
   
    def self.for_user(user)
      return ZimbraInterceptingProxy::Config.new_backend if user.migrated?
      ZimbraInterceptingProxy::Config.old_backend
    end
    
  end
end