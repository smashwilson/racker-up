# create a new A record when passed an FQDN and IP address as arguments.

require 'fog'

# since we don't *really* have a domain registered.
Fog.mock!

require_relative 'boilerplate'
require 'optparse'

fqdn, ip, email = nil, nil, nil
opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} -f DOMAINNAME -i 1.2.3.4 -e myname@email.com"

  opts.on('-f', '--fqdn DOMAINNAME', 'The domain name.') do |d|
    fqdn = d
  end
  opts.on('-i', '--ip', 'The IP address to register.') do |i|
    ip = i
  end
  opts.on('-e', '--email', 'The email address to use as a POC.') do |e|
    email = e
  end
  opts.on('-h', '--help', "You're looking at it.") do
    puts opts
    exit 0
  end
end

opts.parse! ARGV

unless fqdn && ip && email
  puts opts
  exit 1
end

service = log_me_in Fog::DNS

step "creating a zone for the address."
zone = service.zones.create domain: fqdn, email: email

puts " zone created with nameservers: #{zone.nameservers.join ', '}"

step "adding an A record to the zone."
record = zone.records.create(
  value: ip,
  name: fqdn,
  type: 'A'
)

step "complete."
