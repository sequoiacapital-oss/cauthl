require 'signet/oauth_2/client'
require 'openssl'
require 'json/jwt'

module Cauthl
  class ATGCommon
    FUZZY_REFRESH_SECONDS = 120

    attr_reader :client

    def initialize(scope:nil)
      @force_fetch = true
      @additional_parameters = {}
      @scope = scope
    end

    def token
      if @force_fetch
        @force_fetch = false
        @client.fetch_access_token!(scope: @scope, additional_parameters: @additional_parameters)
      elsif Time.now > @client.expires_at - FUZZY_REFRESH_SECONDS
        @client.fetch_access_token!(scope: @scope, additional_parameters: @additional_parameters)
      end

      @client.access_token
    end

    def token!
      @force_fetch = true
      token
    end   
  end

  class AccessTokenGenerator < ATGCommon

    def initialize(client_id:, client_secret:, token_credentials_uri:, scope: nil)
      super(scope: scope)

      @client = Signet::OAuth2::Client.new(
        :token_credential_uri => token_credentials_uri,
        :client_id => client_id,
        :client_secret => client_secret
      )
      @client.grant_type = "client_credentials"
    end
  end

  class JWTAccessTokenGenerator < ATGCommon




    def initialize(client_id:, client_private_key:, token_credentials_uri:, scope: nil)
      super(scope: scope)

      @pk = OpenSSL::PKey::RSA.new(client_private_key)
      @claim = {
        iss: client_id,
        sub: client_id,
        aud: token_credentials_uri
      }

      @client = Signet::OAuth2::Client.new(
        token_credential_uri: token_credentials_uri
      )
      @client.grant_type = "client_credentials"
      
    end

    def token
      @claim["exp"] = Time.now.to_i + 3600

      jws = JSON::JWT.new(@claim).sign(@pk, :RS256).to_s
      @additional_parameters = {"client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer", "client_assertion": jws}

      super
    end    
  end
end
