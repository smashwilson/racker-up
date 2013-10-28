# common login boilerplate for the fog exercises

require 'dotenv'
require 'fog'

Dotenv.load

def log_me_in service_kind = Fog::Compute
  username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']

  service_kind.new(
    provider: 'Rackspace',
    rackspace_username: username,
    rackspace_api_key: key
  )
end
