# Exercise the Cloud Queues API.

require_relative 'boilerplate'
require 'optparse'

qname = 'default-queue'
mode = :producer

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} -q NAME [-p|--producer] OR [-c|--consumer]"

  opts.on('-q', '--queue NAME', 'Name of the queue to manipulate.') do |name|
    qname = name
  end

  opts.on('-p', '--producer', 'Publish items to a queue.') do
    mode = :producer
  end

  opts.on('-c', '--consumer', 'Consume items from a queue.') do
    mode = :consumer
  end

  opts.on('-h', '--help', "You're looking at it!") do
    puts opts
    exit 0
  end
end
opts.parse! ARGV

service = log_me_in Fog::Rackspace::Queues

step "find or create the queue \"#{qname}\""
q = service.queues.get(qname) || service.queues.create(name: qname)

case mode
when :producer
  i = 0
  loop do
    substep "publishing message #{i}"
    q.messages.create body: { text: "item-#{i}", count: i }, ttl: 3600
    sleep 2
    i += 1
  end
when :consumer
  loop do
    claim = q.claims.create ttl: 3600, grace: 60

    if claim
      step "claimed #{claim.messages.size} messages"
      claim.messages.each do |m|
        substep "consuming: #{m.body}"
        m.destroy
      end
      substep "releasing claim"
      claim.destroy
    else
      step "nothing to claim"
    end

    sleep 10
  end
end
