# Racker Up

This is a series of exercises to familiarize myself with Rackspace's OpenStack API, using Ruby, [HTTParty](http://httparty.rubyforge.org/rdoc/) and [fog](https://github.com/fog/fog). It might be useful to someone as a reference, too.

 - `raw-api.rb` uses the OpenStack API directly to:
  - log in to the authentication endpoint, printing the token and tenant IDs;
  - enumerate the service catalog;
  - enumerate the user's active cloud servers;
  - list the flavors and images available on a chosen endpoint;
  - launch a new cloud server;
  - wait for the server to be ready, printing progress;
  - destroy the server that was just launch.
 - `challenge-1.rb` launches and destroys three servers.
 - `challenge-2.rb` clones an existing server.
 - `challenge-3.rb` uploads the contents of a directory to a cloud files container.
 - `challenge-4.rb` creates an A record for a DNS entry.
 - `challenge-5.rb` creates a cloud database.
