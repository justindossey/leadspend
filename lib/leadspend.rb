##
# Leadspend API implementation for Ruby
# = Leadspend
#   This (top-level) module contains constants based on the API specification.
module Leadspend
  DEFAULT_SERVERS = %w{primary.api.leadspend.com secondary.api.leadspend.com}
  DEFAULT_VERSION = "v2"
  MIN_TIMEOUT = 3
  MAX_TIMEOUT = 15
  RESULT_STATUSES = ['unknown','verified','disposable', 'unreachable', 'undeliverable', 'illegitimate']
end
require "#{File.dirname(__FILE__)}/leadspend/exceptions"
require "#{File.dirname(__FILE__)}/leadspend/result"
require "#{File.dirname(__FILE__)}/leadspend/client"


