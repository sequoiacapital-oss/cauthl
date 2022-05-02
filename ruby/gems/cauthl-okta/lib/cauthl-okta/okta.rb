require 'signet/oauth_2/client'

module Cauthl
  module Okta
    class TokenGenerator

      attr_reader :client

      def initialize(client_id:, client_secret:, token_credentials_uri:, scopes: [])

        @client = Signet::OAuth2::Client.new(
          :token_credential_uri => token_credentials_uri,
          :client_id => client_id,
          :client_secret => client_secret,
          :scopes => scopes
        )
        @client.grant_type = "client_credentials"
        
        @first_time = true
      end

      def access_token
        if @first_time
          @first_time = false
          @client.refresh!
        elsif Time.now > @client.expires_at + 120
          @client.refresh!
        end

          @client.access_token
      end
    end
  end
end