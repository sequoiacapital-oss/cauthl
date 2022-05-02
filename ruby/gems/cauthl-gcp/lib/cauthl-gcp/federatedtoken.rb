require 'cauthl-okta'
require 'google-apis-iamcredentials_v1'

module Cauthl
  module Gcp
    class FederatedToken
      def initialize(st, service_account:, scopes: [])
        @s = Google::Apis::IamcredentialsV1::IAMCredentialsService.new
        @s.authorization = st

        @req = Google::Apis::IamcredentialsV1::GenerateAccessTokenRequest.new(
          scope: scopes + ["https://www.googleapis.com/auth/cloud-platform"]
        )
        @sa = "projects/-/serviceAccounts/" + service_account
      end

      def token
        if expired?
          @token = @s.generate_service_account_access_token(@sa, @req)
        end
        @token
      end

      def expired?
        if @token.nil?
          @token = @s.generate_service_account_access_token(@sa, @req)
        end

        Time.now > Time.parse(@token.expire_time)
      end

      def apply! a_hash, opts = {}
        a_hash[Signet::OAuth2::AUTH_METADATA_KEY] = "Bearer #{token.access_token}"
      end
    end
  end
end