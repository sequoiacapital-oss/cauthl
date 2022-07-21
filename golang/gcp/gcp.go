package gcp

import (
	"context"
	"fmt"
	"time"

	iamcredentials "cloud.google.com/go/iam/credentials/apiv1"
	"golang.org/x/oauth2"
	"google.golang.org/api/option"
	"google.golang.org/api/sts/v1"
	iamcredentialspb "google.golang.org/genproto/googleapis/iam/credentials/v1"
)

type STSTokenSource struct {
	ctx         context.Context
	ts          oauth2.TokenSource
	stsAudience string
}

func (s *STSTokenSource) Token() (*oauth2.Token, error) {
	c, err := sts.NewService(s.ctx, option.WithoutAuthentication())

	if err != nil {
		return nil, err
	}

	t, err := s.ts.Token()

	if err != nil {
		return nil, err
	}

	v1s := sts.NewV1Service(c)

	req := &sts.GoogleIdentityStsV1ExchangeTokenRequest{
		Audience:           s.stsAudience,
		Scope:              "https://www.googleapis.com/auth/cloud-platform",
		GrantType:          "urn:ietf:params:oauth:grant-type:token-exchange",
		RequestedTokenType: "urn:ietf:params:oauth:token-type:access_token",
		SubjectTokenType:   "urn:ietf:params:oauth:token-type:jwt",
		SubjectToken:       t.AccessToken,
	}

	stsToken, err := v1s.Token(req).Do()

	if err != nil {
		return nil, err
	}

	return &oauth2.Token{
		AccessToken: stsToken.AccessToken,
		Expiry:      time.Now().Add(time.Second * time.Duration(stsToken.ExpiresIn)),
	}, nil
}

type FederatedTokenSource struct {
	ctx            context.Context
	Scopes         []string
	ServiceAccount string
	ts             oauth2.TokenSource
}

func (s *FederatedTokenSource) Token() (*oauth2.Token, error) {
	if s.Scopes == nil {
		s.Scopes = make([]string, 0)
	}

	c, err := iamcredentials.NewIamCredentialsClient(s.ctx, option.WithTokenSource(oauth2.ReuseTokenSource(nil, s.ts)))

	if err != nil {
		return nil, err
	}

	defer c.Close()

	req := &iamcredentialspb.GenerateAccessTokenRequest{
		Scope: append(s.Scopes, "https://www.googleapis.com/auth/cloud-platform"),
		Name:  fmt.Sprintf("projects/-/serviceAccounts/%s", s.ServiceAccount),
	}
	t, err := c.GenerateAccessToken(s.ctx, req)

	if err != nil {
		return nil, err
	}

	return &oauth2.Token{
		AccessToken: t.AccessToken,
		Expiry:      t.ExpireTime.AsTime(),
	}, nil
}

type FederatedTokenSourceConfig struct {
	// WorkloadIdentityProvider: The string name of the WIP.
	// e.g.: "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_NAME/providers/PROVIDER_NAME"
	WorkloadIdentityProvider string

	// ServiceAccount: The full name of the service account.
	// e.g.: "myservice-account@my-project-id.iam.gserviceaccount.com"
	ServiceAccount string

	Scopes []string

	// OriginatingTokenSource: an oauth2.TokenSource that will be used to get the originating JWT for the STS process
	OriginatingTokenSource oauth2.TokenSource
}

func NewFederatedTokenSource(ctx context.Context, config FederatedTokenSourceConfig) oauth2.TokenSource {
	return &FederatedTokenSource{
		ctx:            ctx,
		ServiceAccount: config.ServiceAccount,
		Scopes:         config.Scopes,
		ts: &STSTokenSource{
			ctx:         ctx,
			stsAudience: config.WorkloadIdentityProvider,
			ts:          config.OriginatingTokenSource,
		},
	}
}
