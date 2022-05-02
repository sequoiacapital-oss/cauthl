# frozen_string_literal: true

require 'aws-sdk-core'

#
#     role_credentials = Cauthl::Aws::AssumeRoleOIDCClientCredentials.new(
#       idp: Cauthl::OktaTokenGenerator.new(...) 
#       role_arn: "arn:aws:...."
#       role_session_name: "session-name"
#       ...
#     )
#     For full list of parameters accepted
#     @see Aws::STS::Client#assume_role_with_web_identity
#
module Cauthl
  module Aws
    class AssumeRoleOIDCClientCredentials < ::Aws::AssumeRoleWebIdentityCredentials

      def initialize(options = {})
        @idp = options.delete(:idp)
        super
      end

      def inspect
        "#<#{self.class.name} client_id=#{@idp.client.client_id}>"
      end

      private

      # Override the _token_from_file
      def _token_from_file(filename)
        _get_token
      end

      def _get_token
        @idp.access_token
      end

    end
  end
end