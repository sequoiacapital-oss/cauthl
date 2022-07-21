# frozen_string_literal: true

require_relative 'spec_helper'
require 'aws-sdk-core'
require 'cauthl-aws'

module Cauthl
  module Aws
    describe AssumeRoleOIDCClientCredentials do
      subject { AssumeRoleOIDCClientCredentials.new(
        role_arn: 'arn',
        token_source: @token_source,
        role_session_name: "session-name"
      )}

      let(:in_one_hour) { Time.now + 60 * 60 }

      let(:expiration) { in_one_hour }

      let(:credentials) {
        double('credentials',
          access_key_id: 'akid',
          secret_access_key: 'secret',
          session_token: 'session',
          expiration: expiration,
        )
      }

      let(:token_url) {
       "https://token.url/v1/token"
      }

      let (:access_token) {
        "access_token_contents"
      }

      let(:resp_body) {
        '{"token_type":"Bearer","expires_in":3600,"access_token":"' + access_token + '","scope":"awstest"}'
      }

      let(:resp) {double('client-resp', credentials: credentials)}

      before(:each) do
        @client = double
        allow(::Aws::STS::Client).to receive(:new).and_return(@client)
        allow(@client).to receive(:assume_role_with_web_identity).and_return(resp)
        stub_request(:post, token_url).to_return(status: 200, body: resp_body)
        @token_source = double
      end

      it 'properly creates an STS client with assume_role_with_web_identity' do
        allow(@token_source).to receive(:token).and_return(access_token)

        expect(@client).to receive(:assume_role_with_web_identity).with({
          role_arn: 'arn',
          web_identity_token: JSON(resp_body)["access_token"],
          role_session_name: "session-name"
        })

        subject
      end

      context 'token url returns a non-200 status code' do
        before do 
          stub_request(:post, token_url).to_return(status: 401, body: resp_body)
        end

        it 'raises an exception' do
          allow(@token_source).to receive(:access_token).and_raise(StandardError)

          expect { subject }.to raise_error(Exception)
        end
      end
    end
  end
end