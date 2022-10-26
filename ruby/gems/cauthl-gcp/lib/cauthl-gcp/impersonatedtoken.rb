require 'google-apis-iamcredentials_v1'
require 'json'

module Cauthl
  module Gcp
    class ImpersonatedToken
      DEFAULT_AUD = "https://oauth2.googleapis.com/token"

      def initialize(ft, service_account:, impersonated_user:, scopes: [], aud: DEFAULT_AUD)
        @s = Google::Apis::IamcredentialsV1::IAMCredentialsService.new
        @s.authorization = ft

        @jwt = {}
        @jwt["iss"] = service_account
        @jwt["aud"] = aud
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
        a_hash[Signet::OAuth2::AUTH_METADATA_KEY] = "Bearer #{token}"
      end

      def apply a_hash, opts = {}
        a_copy = a_hash.clone
        apply! a_copy, opts
        a_copy
      end

      def updater_proc
        proc { |a_hash, opts = {}| apply a_hash, opts }
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
