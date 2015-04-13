require "zimbra_intercepting_proxy"

require 'minitest/autorun'
require 'minitest/reporters' # requires the gem

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress

ZimbraInterceptingProxy::Config.domain="example.com"
ZimbraInterceptingProxy::Config.migrated_users_file="./test/fixtures/users.yml"
ZimbraInterceptingProxy::Config.old_backend = "old-mailbox.example.com"
ZimbraInterceptingProxy::Config.new_backend = "new-mailbox.zboxapp.com"