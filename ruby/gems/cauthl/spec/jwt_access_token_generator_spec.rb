# frozen_string_literal: true

require 'cauthl/access_token_generator'
require 'timecop'
require 'openssl'

module Cauthl

  describe JWTAccessTokenGenerator do
    subject { JWTAccessTokenGenerator.new(
      client_id: client_id,
      client_private_key: client_private_key.to_pem,
      token_credentials_uri: token_uri,
      scope: scope
    )}

    let(:client_id) { "oidc-client-id" } 
    let(:client_private_key) { (OpenSSL::PKey::RSA.generate 2048) }
    let(:token_uri) { "http://token.uri/token" }
    let(:scope) { ["test-scope"] }
    let(:token_expiry_seconds) { 1800 }


    context "creation" do
      it "initializes the Signet client with nil client values" do
        expect(subject.client.client_id).to be_nil
        expect(subject.client.client_secret).to be_nil
      end
    end

    context "fetching" do
      before(:each) do
        @client = double
        allow(Signet::OAuth2::Client).to receive(:new).and_return(@client)
        allow(@client).to receive(:access_token)
        allow(@client).to receive(:expires_at).and_return(Time.now + token_expiry_seconds)

        expect(@client).to receive(:grant_type=).with("client_credentials")
      end

      it "builds an assertion" do
        Timecop.freeze
        claim = {iss: client_id, sub: client_id, aud: token_uri, exp: Time.now.to_i + 3600}
        assertion = JSON::JWT.new(claim).sign(client_private_key, :RS256).to_s

        expect(@client).to receive(:fetch_access_token!).with(scope: scope, additional_parameters: {client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer", client_assertion: assertion}).once
        subject.token!
      end

      it "fetches an access token only once" do
        expect(@client).to receive(:fetch_access_token!).with(scope: scope, additional_parameters: {client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer", client_assertion: anything}).once
        subject.token
        subject.token
      end

      context "refreshes the token" do
        before(:each) do
          expect(@client).to receive(:fetch_access_token!).with(scope: scope, additional_parameters: {client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer", client_assertion: anything}).twice
        end

        it "always refreshes if the token! method is used" do
          subject.token!
          subject.token!
        end
  
        it "refetches the access token if it has expired" do
          subject.token
          Timecop.travel(Time.now + (token_expiry_seconds*2))
          subject.token       
        end
  
        it "refreshes if the access token is not expired but we're in the fuzzy grace period" do
          subject.token
          Timecop.travel(@client.expires_at - 2)
          subject.token         
        end

      end
    end
  end
end