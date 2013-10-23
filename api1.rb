# Authenticate against the API.

require 'httparty'
require 'json'
require 'dotenv'

Dotenv.load

Session = Struct.new(:token_id, :tenant_id)

class AuthenticationEndpoint
  include HTTParty

  base_uri 'https://identity.api.rackspacecloud.com/v2.0'

  def self.login!
    username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']
    body = {auth: {'RAX-KSKEY:apiKeyCredentials' => {username: username, apiKey: key}}}
    headers = {'Content-Type' => 'application/json'}
    resp = post('/tokens', headers: headers, body: body.to_json).parsed_response
    token_info = resp['access']['token']
    Session.new(token_info['id'], token_info['tenant']['id'])
  end
end

session = AuthenticationEndpoint.login!
puts "Token ID: #{session.token_id}"
puts "Tenant ID: #{session.tenant_id}"
