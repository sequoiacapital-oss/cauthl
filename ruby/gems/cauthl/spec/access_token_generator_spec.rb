# frozen_string_literal: true

require 'cauthl/access_token_generator'
require 'timecop'

module Cauthl

  describe AccessTokenGenerator do
    subject { AccessTokenGenerator.new(
      client_id: client_id,
      client_secret: client_secret,
      token_credentials_uri: token_uri,
      scope: scope
    )}

    let(:client_id) { "oidc-client-id" } 
    let(:client_secret) { "oidc-client-secret" }
    let(:token_uri) { "http://token.uri/token" }
    let(:scope) { ["test-scope"] }
    let(:token_expiry_seconds) { 1800 }


    context "creation" do
      it "initializes the Signet client" do
        expect(subject.client.client_id).to equal(client_id)
        expect(subject.client.client_secret).to equal(client_secret)
      end
    end


    context "fetching" do
      before(:each) do
        @client = double
        allow(Signet::OAuth2::Client).to receive(:new).and_return(@client)
        allow(@client).to receive(:grant_type=).with("client_credentials")
        allow(@client).to receive(:access_token)
        allow(@client).to receive(:expires_at).and_return(Time.now + token_expiry_seconds)
      end

      it "fetches an access token only once" do
        expect(@client).to receive(:fetch_access_token!).with(scope: scope, additional_parameters: {}).once
        subject.token
        subject.token
      end

      context "refreshes the token" do
        before(:each) do
          expect(@client).to receive(:fetch_access_token!).with(scope: scope, additional_parameters: {}).twice
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