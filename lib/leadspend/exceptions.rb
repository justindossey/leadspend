##
# = Leadspend Exceptions.  
#   The status code from the Leadspend server determines which exception is raised by the client.
module Leadspend
  module Exceptions
    class LeadspendException < Exception; end
    class BadRequestException < LeadspendException ; end
    class UnknownResponseException < LeadspendException ; end
    class UnauthorizedRequestException < LeadspendException ; end
    class ServerException < LeadspendException; end
    class ServerBusyException < LeadspendException ; end
  end
end
