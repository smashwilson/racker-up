# Authenticate against the API.

require 'httparty'
require 'json'
require 'dotenv'

Dotenv.load

class AuthenticationEndpoint
  include HTTParty

  base_uri 'https://identity.api.rackspacecloud.com/v2.0'

  def self.login!
    username, key = ENV['RAX_USERNAME'], ENV['RAX_APIKEY']
    body = {auth: {'RAX-KSKEY:apiKeyCredentials' => {username: username, apiKey: key}}}
    headers = {'Content-Type' => 'application/json'}
    post(headers: headers, body: body.to_json)
  end
end

puts AuthenticationEndpoint.login!.inspect
