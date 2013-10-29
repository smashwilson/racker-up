# Build three 512MB cloud servers that follow a similar naming convention
# (i.e., web1, web2, web3) and return the IP and login credentials for each server.

require_relative 'boilerplate'

service = log_me_in

step "finding the appropriate flavor and image."

flavor = service.flavors.find { |f| f.ram == 512 }
raise "Cannot find flavor!" if flavor.nil?

image = service.images.find { |i| i.name =~ /Ubuntu 13.10/ }
raise "Cannot find image!" if image.nil?

step "launching three servers."
boxen = (1..3).map do |index|
  box = service.servers.create name: "web#{index}",
    image_id: image.id,
    flavor_id: flavor.id
  puts ".. Server web#{index} launching."
  box
end

progress("wait for all three to launch.") do
  boxen.each do |b|
    b.wait_for { ready? }
    puts ".. Server #{b.name} ready."
  end
end

step "print the IP and login credentials for each server."
boxen.each do |b|
  addr = b.addresses['public'].find { |a| a['version'] == 4 }['addr']
  puts ".. Server: #{b.name} => IP: #{addr} password: #{b.password}"
end

step "shut them down."
boxen.each { |b| b.destroy }

