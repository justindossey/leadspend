require 'rubygems'
require 'fakeweb'
require "#{File.dirname(__FILE__)}/../../../init"
class Leadspend::Server
  def initialize(username, password, opts={})
    @username = username
    @password = password
    options = opts
    @servers = options[:servers] || Leadspend::DEFAULT_SERVERS
    @api_version = options[:version] || Leadspend::DEFAULT_VERSION
    FakeWeb.allow_net_connect = false
    register_all_urls
  end

  def unregister_all_urls
    FakeWeb.clean_registry
  end

  def register_all_urls
    @servers.each do |server|
      Leadspend::RESULT_STATUSES.each do |status|

        http_status = [200, 'OK']
        email = "#{status}-#{http_status.first}@example.com"
        #$stderr.puts("Registering #{url_for(server, email)}")
        FakeWeb.register_uri(:get, url_for(server, email), 
                             :body => Leadspend::Result.send(status, email).raw, 
                             :status => http_status)
        [Leadspend::MIN_TIMEOUT, Leadspend::MAX_TIMEOUT, (Leadspend::MIN_TIMEOUT-1), (Leadspend::MAX_TIMEOUT+1)].each do |timeout|
          #$stderr.puts("Registering #{url_for(server, email, :timeout => timeout)}")
          FakeWeb.register_uri(:get, url_for(server, email, :timeout => timeout),
                               :body => Leadspend::Result.send(status, email).raw, 
                               :status => http_status)
        end

        # non-200 statuses

        # for 202, have it be "unknown". 
        http_status = [202, 'Accepted']
        email = "#{status}-#{http_status.first}@example.com"
        FakeWeb.register_uri(:get, url_for(server, email), 
                             :body => Leadspend::Result.unknown(email).raw, 
                             :status => http_status)
        

        # 401 and 400 should cause the client to raise an exception
        [[400, 'Bad Request'], [401, 'Unauthorized']].each do |http_status|
          email = "verified-#{http_status.first}@example.com"
          FakeWeb.register_uri(:get, url_for(server, email), :body => 'Error!', :status => http_status)
        end
      end
    end

    # for 500 and 503, make this work on secondary, but not primary-- this means we can test failover
    [[500, 'Internal Server Error'],[503, 'Service Unavailable']].each do |http_status|
      email = "verified-#{http_status.first}@example.com"
      FakeWeb.register_uri(:get, url_for(@servers.first, email), :body => 'Error!', :status => http_status)
      new_http_status = [200, 'OK']
      FakeWeb.register_uri(:get, url_for(@servers.last, email), 
                           :body => Leadspend::Result.verified(email).raw, 
                           :status => new_http_status )

      # also register an "alwaysfail" address to see that the proper exception is raised
      email = "alwaysfail-#{http_status.first}@example.com"
      @servers.each do |server|
        FakeWeb.register_uri(:get, url_for(server, email), :body => 'Error!', :status => http_status)
      end
    end
  end

  def url_for(server, email, opts={})
    opts_str = ''
    unless opts.empty?
      opts_str += '?' + opts.map { |k,v| "#{k.to_s}=#{escape_param(v)}"}.join('&')
    end
    "https://#{@username}:#{@password}@#{server}/#{@api_version}/validity/#{escape_param email}#{opts_str}"
  end

  def escape_param(param)
    URI::escape(param.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
