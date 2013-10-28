# clone a server

require_relative 'boilerplate'

service = log_me_in

# pick a server you've already got running.
# look for the smallest one.
src_server = service.servers.min_by { |s| s.flavor.ram }
raise "You must have at least one server to run this exercise." if src_server.nil?

puts ">> cloning server: #{src_server.name}"

puts ".. creating image."
image = src_server.create_image 'temp-image'

puts ".. waiting for image to be ready."
image.wait_for { ready? }

puts ".. creating new server from image."
target_server = service.servers.create name: 'target-server',
  image_id: image.id, flavor_id: src_server.flavor.id

puts ".. waiting for server to launch."
target_server.wait_for { ready? }

puts ">> server cloned!"
