require 'google-apis-iamcredentials_v1'
require 'json'

module Cauthl
  module Gcp
    class ImpersonatedToken
      def initialize(ft, service_account:, impersonated_user:, scopes: [])
        @s = Google::Apis::IamcredentialsV1::IAMCredentialsService.new
        @s.authorization = ft

        @jwt = {}
        @jwt["iss"] = service_account
        @jwt["aud"] = "https://oauth2.googleapis.com/token"
        @jwt["scope"] = scopes.join(" ")
        @jwt["sub"] = impersonated_user

        @sa = "projects/-/serviceAccounts/" + service_account
      end

      def token
        if expired?
          @token = @s.sign_service_account_jwt(@sa, build_req).signed_jwt
        end
        @token
      end

      def expired?
        @jwt["exp"].nil? || Time.now.to_i > @jwt["exp"] - 120
      end

      def apply! a_hash, opts = {}
        a_hash[Signet::OAuth2::AUTH_METADATA_KEY] = "Bearer #{@token}"
      end

      private

      def build_req
        @jwt["iat"] = Time.now.to_i
        @jwt["exp"] = Time.now.to_i + 3600
      
        Google::Apis::IamcredentialsV1::SignJwtRequest.new(
          payload: @jwt.to_json
        )
      end
    end
  end
end
