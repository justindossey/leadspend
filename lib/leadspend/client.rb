require 'net/https'
## 
# = Leadspend Client
#   The primary interface to Leadspend.
#   Use it like so:
# client = Leadspend::Client.new(LEADSPEND_USERNAME, LEADSPEND_PASSWORD, :ca_file => CA_FILE, :timeout => 5)
# is_valid_email = client.validate(params[:email) # true if verified or unknown, false otherwise
# If you want more information about the response, use something like
# leadspend_result = client.fetch_result(params[:email])
# This will return a Leadspend::Result object representing the JSON response,
# with convenience methods like unreachable? and illegitimate?.

class Leadspend::Client
  # Instantiate a client.
  # Recommended options: :ca_file is the full path to a CA Cert file.
  # :timeout is the server-side timeout in seconds, between 3 and 15.  If a
  # result is not available within the timeout, the response will be an
  # "unknown" result.
  def initialize(username, password, opts={})
    options = opts
    if defined?(HashWithIndifferentAccess)
      options = HashWithIndifferentAccess.new(opts)
    end
    @servers = options[:servers] || Leadspend::DEFAULT_SERVERS
    @api_version = options[:version] || Leadspend::DEFAULT_VERSION
    # path to the CA file: download http://curl.haxx.se/ca/cacert.pem and put
    # it someplace on your server.
    @ca_file = options[:ca_file]

    # set the JSON parser to use.  Use the one specified, or choose a reasonable default.
    case options[:json_parser]
    when 'yajl'
      Leadspend::Result.json_parser=Leadspend::Parser::YajlParser
    when 'rails'
      Leadspend::Result.json_parser=Leadspend::Parser::RailsParser
    when 'json'
      Leadspend::Result.json_parser=Leadspend::Parser::JSONParser
    else
      if defined? Rails
        Leadspend::Result.json_parser=Leadspend::Parser::RailsParser
      else
        Leadspend::Result.json_parser=Leadspend::Parser::JSONParser
      end
    end

    @username = username
    @password = password
    @server_index = 0

    @request_options = {}
    # optional: allow a server timeout.  Minimum is 3, max is 15
    if options[:timeout]
      @request_options[:timeout] = options[:timeout].to_i
      if @request_options[:timeout] < Leadspend::MIN_TIMEOUT
        @request_options[:timeout] = Leadspend::MIN_TIMEOUT
      elsif @request_options[:timeout] > Leadspend::MAX_TIMEOUT
        @request_options[:timeout] = Leadspend::MAX_TIMEOUT
      end
    end
  end

  # Return a boolean based on whether an address is valid or not.  
  # Valid statuses: unknown, validated.  
  # Invalid statuses: anything else.
  def validate(address)
    result = fetch_result(address)
    return result.verified? || result.unknown?
  end

  # fetch a result from Leadspend, doing failover if necessary.  R
  # Returns a Leadspend::Result object if successful, or an exception if there was a failure.
  def fetch_result(address)
    retry_once = true
    begin
      result = query("/#{@api_version}/validity", address, @request_options)
    rescue Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET, IOError,
          Leadspend::Exceptions::ServerException, Leadspend::Exceptions::ServerBusyException
      if retry_once 
        retry_once = false
        @server_index = (@server_index + 1) % @servers.length
        retry
      else
        raise $!
      end
    end
  end

  private
  # do a full uri escape on a value for HTTP
  def escape_param(param) # :nodoc:
    URI::escape(param.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  # Do a request to Leadspend and return a Leadspend::Result or exception.
  def query(base, address, param_hash) # :nodoc:
    http = Net::HTTP.new(@servers[@server_index], 443)
    http.use_ssl = true
    if @ca_file
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = @ca_file
    end
    if param_hash.empty?
      request_path = [base, escape_param(address)].join('/')
    else
      param_str = param_hash.map{|k,v| [k.to_s, escape_param(v)].join('=')}.join('&')
      request_path = [[base, escape_param(address)].join('/'), param_str].join('?')
    end
    http.start do 
      request = Net::HTTP::Get.new(request_path)
      request.basic_auth @username, @password
      response = http.request(request)
      case response.code.to_i 
      when 200
        return Leadspend::Result.new(response.body)
      when 202
        return Leadspend::Result.unknown(address)
      when 400
        raise Leadspend::Exceptions::BadRequestException, response.body
      when 401
        raise Leadspend::Exceptions::UnauthorizedRequestException, response.body
      when 500
        raise Leadspend::Exceptions::ServerException, response.body
      when 503
        raise Leadspend::Exceptions::ServerBusyException, response.body
      else
        raise Leadspend::Exceptions::UnknownResponseException, response.body
      end
    end
  end
end
