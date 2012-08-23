require 'json'

class Leadspend::Result
  @@json_parser=nil
  def initialize(json_string)
    @raw = json_string
    @result = self.class.decode_json(json_string)
  end

  def self.json_parser=(p)
    @@json_parser = p
  end

  def raw
    @raw
  end

  def result
    @result['result']
  end

  Leadspend::RESULT_STATUSES.each do |status|
    define_method("#{status}?") { result == status }
  end

  def self.method_missing(meth, *args, &block)
    if Leadspend::RESULT_STATUSES.index(meth.to_s)
      generate_result(meth.to_s, *args)
    else
      super
    end
  end

  def self.respond_to?(meth)
    Leadspend::RESULT_STATUSES.include?(meth.to_s) || super
  end

  def ==(other)
    other.is_a?(Leadspend::Result) and other.address == self.address and other.result == self.result
  end
 
  def address
    @result['address']
  end

  # extended attributes

  def role?
    result['role']
  end
  
  def full?
    undeliverable? and result['full']
  end

  def timeout?
    unknown? and result['timeout']
  end

  def retry_seconds
    unknown? and result['retry']
  end


  private
  def self.generate_result(status, address, opts={})
    new(encode_json({'result' => status, 'address' => address}.merge(opts)))
  end

  def self.decode_json(json_string)
    json_parser.decode(json_string)
  end

  def self.encode_json(object)
    json_parser.encode(object)
  end

  def self.json_parser
    if @@json_parser.nil?
      unless defined?(Leadspend::Parser::JSONParser)
        require "#{File.dirname(__FILE__)}/parser/json_parser"
      end
      @@json_parser = Leadspend::Parser::JSONParser
    end
    @@json_parser
  end
  
 
end
