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

CloudServer = Struct.new(:name, :id)

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
end

# Authenticate and report the token and tenant.
puts ">> Authentication"
session = AuthenticationEndpoint.login!
puts "Token ID: #{session.token_id}"
puts "Tenant ID: #{session.tenant_id}"

# Enumerate the user's service catalog.
puts
puts ">> Service catalog"
session.catalog.each do |entry|
  puts "#{entry.name}:"
  entry.endpoints.each do |url|
    puts " #{url}"
  end
end

# Enumerate the user's cloud servers (across all endpoints).
puts
puts ">> Active cloud servers"
CloudServers.new(session).list.each do |s|
  puts " Server: #{s.name} id: #{s.id}"
end
