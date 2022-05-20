require 'signet/oauth_2/client'

module Cauthl
  module Okta
    class TokenGenerator

      attr_reader :client

      FUZZY_REFRESH_SECONDS = 120

      def initialize(client_id:, client_secret:, token_credentials_uri:, scope: nil)
        @scope = scope

        @client = Signet::OAuth2::Client.new(
          :token_credential_uri => token_credentials_uri,
          :client_id => client_id,
          :client_secret => client_secret
        )
        @client.grant_type = "client_credentials"
        
        @first_time = true
      end

      def access_token
        if @first_time
          @first_time = false
          @client.fetch_access_token!(scope: @scope)
        elsif Time.now > @client.expires_at + FUZZY_REFRESH_SECONDS
          @client.fetch_access_token!(scope: @scope)
        end

          @client.access_token
      end
    end
  end
end