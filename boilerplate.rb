# common login boilerplate for the fog exercises

require 'dotenv'
require 'fog'
require 'colored'

Dotenv.load

def log_me_in service_kind = Fog::Compute
  username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']

  auth_hash = {
    rackspace_username: username,
    rackspace_api_key: key
  }
  auth_hash[:provider] = 'Rackspace' unless service_kind.to_s =~ /Rackspace/

  service_kind.new(auth_hash)
end

def step text
  puts ">>".yellow + " #{text}"
end

def substep text
  puts "..".cyan + " #{text}"
end

def progress text
  print ">>".yellow + " #{text} ..."
  $stdout.flush
  yield
  puts " complete".green
end
