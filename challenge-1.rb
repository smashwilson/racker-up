# Build three 512MB cloud servers that follow a similar naming convention
# (i.e., web1, web2, web3) and return the IP and login credentials for each server.

require_relative 'boilerplate'

service = log_me_in

puts ">> Finding the appropriate flavor and image."

flavor = service.flavors.find { |f| f.ram == 512 }
raise "Cannot find flavor!" if flavor.nil?

image = service.images.find { |i| i.name =~ /Ubuntu 13.10/ }
raise "Cannot find image!" if image.nil?

puts ">> Launching three servers."
boxen = (1..3).map do |index|
  box = service.servers.create name: "web#{index}",
    image_id: image.id,
    flavor_id: flavor.id
  puts ".. Server web#{index} launching."
  box
end

puts ">> Wait for all three to launch."
boxen.each do |b|
  b.wait_for { ready? }
  puts ".. Server #{b.name} ready."
end

puts ">> Print the IP and login credentials for each server."
boxen.each do |b|
  addr = b.addresses['public'].find { |a| a['version'] == 4 }['addr']
  puts ".. Server: #{b.name} => IP: #{addr} password: #{b.password}"
end

puts ">> Shut then down."
boxen.each { |b| b.destroy }

