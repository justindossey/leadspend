require "#{File.dirname(__FILE__)}/../mocks/leadspend/server"
require 'test/unit'
class Leadspend::TestLeadspendClient < Test::Unit::TestCase
 def setup
   @server = Leadspend::Server.new(:username => 'test', :password => 'test')
   @client = Leadspend::Client.new(:username => 'test', :password => 'test')
 end

 def test_yajl_backend
   @client = Leadspend::Client.new(:username => 'test', :password => 'test', :json_parser => 'yajl')
   verified_email="verified-200@example.com"
   unknown_email="unknown-200@example.com"
   assert @client.validate(verified_email)
   assert @client.validate(unknown_email)
 end

 def test_rails_backend
   @client = Leadspend::Client.new(:username => 'test', :password => 'test', :json_parser => 'rails')
   verified_email="verified-200@example.com"
   unknown_email="unknown-200@example.com"
   assert @client.validate(verified_email)
   assert @client.validate(unknown_email)
 end

 def test_result_consistency
   verified_email="verified-200@example.com"
   unknown_email="unknown-200@example.com"
   assert Leadspend::Result.verified(verified_email).verified?
   assert Leadspend::Result.unknown(unknown_email).unknown?
 end

 def test_validate
   verified_email="verified-200@example.com"
   unknown_email="unknown-200@example.com"
   assert @client.validate(verified_email)
   assert @client.validate(unknown_email)
 end

 def test_ok_results
   Leadspend::RESULT_STATUSES.each do |status|
     email = "#{status}-200@example.com"
     assert_equal Leadspend::Result.send(status, email), @client.fetch_result(email)
   end
 end

 def test_accepted_results
   Leadspend::RESULT_STATUSES.each do |status|
     email = "#{status}-202@example.com"
     assert_equal Leadspend::Result.unknown(email), @client.fetch_result(email)
   end
 end

 def test_400_results
   status='verified'
   email = "#{status}-400@example.com"
   assert_raise(Leadspend::Exceptions::BadRequestException) do 
     @client.fetch_result(email)
   end
 end

 def test_401_results
   status='verified'
   email = "#{status}-401@example.com"
   assert_raise(Leadspend::Exceptions::UnauthorizedRequestException) do 
     @client.fetch_result(email)
   end
 end

 def test_500_failover_results
   status='verified'
   email = "#{status}-500@example.com"
   assert_equal Leadspend::Result.send(status, email), @client.fetch_result(email)
 end

 def test_500_everywhere
   status='alwaysfail'
   email = "#{status}-500@example.com"
   assert_raise(Leadspend::Exceptions::ServerException) do
     @client.fetch_result(email)
   end
 end

 def test_503_failover_results
   status='verified'
   email = "#{status}-503@example.com"
   assert_equal Leadspend::Result.send(status, email), @client.fetch_result(email)
 end

 def test_503_everywhere
   status='alwaysfail'
   email = "#{status}-503@example.com"
   assert_raise(Leadspend::Exceptions::ServerBusyException) do
     @client.fetch_result(email)
   end
 end

 def teardown
   @server.unregister_all_urls unless @server.nil?
 end
end
