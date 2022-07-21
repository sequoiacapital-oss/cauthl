require 'signet/oauth_2/client'

module Cauthl
  class AccessTokenGenerator

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
      
      @force_fetch = true
    end

    def token
      if @force_fetch
        @force_fetch = false
        @client.fetch_access_token!(scope: @scope)
      elsif Time.now > @client.expires_at - FUZZY_REFRESH_SECONDS
        @client.fetch_access_token!(scope: @scope)
      end

      @client.access_token
    end

    def token!
      @force_fetch = true
      token
    end
  end
end