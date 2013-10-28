# Build three 512MB cloud servers that follow a similar naming convention
# (i.e., web1, web2, web3) and return the IP and login credentials for each server.

require 'dotenv'
require 'fog'

Dotenv.load
username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']

service = Fog::Compute.new(
  provider: 'Rackspace',
  rackspace_username: username,
  rackspace_api_key: key
)

# Find the appropriate flavor and image.
flavor = service.flavors.find { |f| f.ram == 512 }
raise "Cannot find flavor!" if flavor.nil?

image = service.images.find { |i| i.name =~ /Ubuntu 13.10/ }
raise "Cannot find image!" if image.nil?

# Launch three servers.
boxen = (1..3).map do |index|
  service.servers.create name: "web#{index}",
    image_id: image.id,
    flavor_id: flavor.id
end

# Wait for all three to start.
boxen.each do |b|
  b.wait_for { ready? }
end

# Print the IP and login credentials for each server.
boxen.each do |b|
  addr = b.addresses['public'].find { |a| a['version'] == 4 }['addr']
  puts "Server: #{b.name} => IP: #{addr} password: #{b.password}"
end

# Shut them down.
boxen.each { |b| b.destroy }

