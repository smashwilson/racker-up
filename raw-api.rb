# Authenticate against the API.

require 'httparty'
require 'json'
require 'dotenv'
require 'pp'

Dotenv.load

Session = Struct.new(:token_id, :tenant_id, :catalog) do
  def auth_headers
    { 'X-Auth-Token' => token_id }
  end
end

CatalogEntry = Struct.new(:name, :endpoints)

CloudServer = Struct.new(:name, :id, :session, :url) do
  def details
    HTTParty.get(url, headers: session.auth_headers).parsed_response
  end

  def progress
    details['server']['progress']
  end

  def delete
    HTTParty.delete(url, headers: session.auth_headers)
  end
end

class AuthenticationEndpoint
  include HTTParty

  base_uri 'https://identity.api.rackspacecloud.com/v2.0'

  def self.login!
    username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']
    body = {auth: {'RAX-KSKEY:apiKeyCredentials' => {username: username, apiKey: key}}}
    headers = {'Content-Type' => 'application/json'}
    resp = post('/tokens', headers: headers, body: body.to_json).parsed_response

    token_info = resp['access']['token']
    entries = resp['access']['serviceCatalog'].map do |service|
      CatalogEntry.new(service['name'], service['endpoints'].map { |e| e['publicURL'] })
    end

    Session.new(token_info['id'], token_info['tenant']['id'], entries)
  end
end

class CloudServers
  include HTTParty

  def initialize session
    @session = session
    entries = @session.catalog.select { |c| c.name == 'cloudServersOpenStack' }
    @endpoints = entries.map(&:endpoints).flatten
  end

  def list
    @endpoints.map do |url|
      resp = self.class.get("#{url}/servers", headers: @session.auth_headers).parsed_response
      resp['servers'].map { |s| CloudServer.new(s['name'], s['id']) }
    end.flatten
  end

  def create endpoint, name, flavor, image
    postbody = { server: { name: name, flavorRef: flavor.id.to_i, imageRef: image.id } }
    headers = @session.auth_headers.merge('Content-Type' => 'application/json')
    resp = HTTParty.post("#{endpoint}/servers", body: postbody.to_json, headers: headers).parsed_response

    link = resp['server']['links'].find { |links| links['rel'] == 'self' }['href']
    CloudServer.new(name, resp['server']['id'], @session, link)
  end
end

class Flavor
  Attrs = %i{id name ram swap vcpus disk}
  attr_accessor *Attrs

  def self.list session, endpoint
    resp = HTTParty.get("#{endpoint}/flavors/detail", headers: session.auth_headers).parsed_response
    resp['flavors'].map do |f|
      Flavor.new.tap do |flavor|
        Attrs.each { |attr| flavor.send("#{attr}=", f[attr.to_s]) }
      end
    end
  end
end

class Image
  Attrs = %i{id name}
  attr_accessor *Attrs

  def self.list session, endpoint
    resp = HTTParty.get("#{endpoint}/images/detail", headers: session.auth_headers).parsed_response
    resp['images'].map do |i|
      Image.new.tap do |image|
        Attrs.each { |attr| image.send("#{attr}=", i[attr.to_s]) }
      end
    end
  end
end

# Authenticate and report the token and tenant.
puts ">> Authentication"
session = AuthenticationEndpoint.login!
puts "Token ID: #{session.token_id}"
puts "Tenant ID: #{session.tenant_id}"

# Enumerate the user's service catalog.
puts
puts ">> Service catalog"
dfw_endpoint = nil
session.catalog.each do |entry|
  puts "#{entry.name}:"
  entry.endpoints.each do |url|
    puts " #{url}"
    # Remember the DFW endpoint for cloudServersOpenStack so we can use it later.
    dfw_endpoint = url if url =~ /dfw/ && entry.name =~ /cloudServersOpenStack/
  end
end

raise "No DFW endpoint!" unless dfw_endpoint

# Enumerate the user's cloud servers (across all endpoints).
puts
puts ">> Active cloud servers"
CloudServers.new(session).list.each do |s|
  puts " Server: #{s.name} id: #{s.id}"
end

# List the flavors available in the DFW endpoint.
puts
puts ">> Flavor list"

standard512 = nil
Flavor.list(session, dfw_endpoint).each do |f|
  puts " Flavor: #{f.id} #{f.name} CPUs: #{f.vcpus} RAM: #{f.ram} swap: #{f.swap} disk: #{f.disk}"

  # Remember the one we want to create.
  standard512 = f if f.name =~ /512MB/
end

raise "No 512MB flavor!" unless standard512

# List the images available in the DFW endpoint.
puts
puts ">> Image list"

ubuntu1310 = nil
Image.list(session, dfw_endpoint).each do |i|
  puts " Image: #{i.id} #{i.name}"
  ubuntu1310 = i if i.name =~ /Ubuntu 13\.10/
end

raise "No Ubuntu 13.10 image!" unless ubuntu1310

# Create a server!
puts
puts ">> Creating a server"

server = CloudServers.new(session).create(dfw_endpoint, 'throwaway', standard512, ubuntu1310)

while (prog = server.progress) != 100
  puts "Progress: #{prog}"
  sleep 10
end

puts ">> Deleting a server"
server.delete
