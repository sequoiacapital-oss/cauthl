require 'google-apis-sts_v1'

module Cauthl
  module Gcp
    class StsToken
      def initialize(idp:, pool:)
        @idp = idp
        @pool = pool
        @s = Google::Apis::StsV1::CloudSecurityTokenService.new
        @token = {}
      end

      def access_token
        if @token["access_token"].nil? || @token["expires_at"].nil? || Time.now > @token["expires_at"] + 120
          req = Google::Apis::StsV1::GoogleIdentityStsV1ExchangeTokenRequest.new(
            audience: @pool,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
            requested_token_type: "urn:ietf:params:oauth:token-type:access_token",
            subject_token: @idp.access_token,
            subject_token_type: "urn:ietf:params:oauth:token-type:jwt")

          resp = @s.token(req)
          @token["access_token"] = resp.access_token
          @token["expires_at"] = Time.now + resp.expires_in
        end
        
        @token["access_token"]
      end

      def apply! a_hash, opts = {}
        a_hash[Signet::OAuth2::AUTH_METADATA_KEY] = "Bearer #{access_token}"
      end

    end
  end
end