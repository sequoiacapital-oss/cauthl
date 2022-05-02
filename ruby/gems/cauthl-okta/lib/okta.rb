require 'signet/oauth_2/client'

module Cauthl
  class OktaToken

    attr_reader :client

    def initialize(client_id:, client_secret:, token_credentials_uri:, scopes: [])
      @client = Signet::OAuth2::Client.new(
        :token_credential_uri => token_credentials_uri,
        :client_id => client_id,
        :client_secret => client_secret,
        :scopes => scopes
      )

      @client.grant_type = "client_credentials"
      @client.refresh!
    end

    def access_token
      if Time.now > @client.expires_at + 120
        @client.refresh!
      else
        @client.access_token
      end
    end
  end
end