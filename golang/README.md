Sample use:

const GCP_WORKLOAD_IDENTITY_PROVIDER = "//iam.googleapis.com/projects/PROJECT_ID/locations/global/workloadIdentityPools/POOL_NAME/providers/PROVISIONER_NAME"
const GCP_SERVICE_ACCOUNT = "your-service-account@your-project.iam.gserviceaccount.com"

func getOktaTokenSource(ctx context.Context) oauth2.TokenSource {
	return cauthl.BuildJWTTokenSource(ctx,
		"client-id",
		"client-private-key",
		"https://your.token.url/v1/token",
		scopes)
}

ts := cauthlgcp.NewFederatedTokenSource(ctx, cauthlgcp.FederatedTokenSourceConfig{
  WorkloadIdentityProvider: GCP_WORKLOAD_IDENTITY_PROVIDER,
  ServiceAccount:           GCP_SERVICE_ACCOUNT,
  OriginatingTokenSource:   getOktaTokenSource(ctx),
  Scopes:                   scopes,
})

# This follows the same lines of the ruby gem. It uses the GCP federation and STS endpoints to generate an access token.

# If you plan to use domain wide delegation for Google Workspace, you will need to impersonate a user. You can do that with this step:

ts2, _ := impersonate.CredentialsTokenSource(ctx, impersonate.CredentialsConfig{
  TargetPrincipal: GCP_SERVICE_ACCOUNT,
  Scopes:          scopes,
  Subject:         "your-impersonated-user@yourdomain.com",
}, option.WithTokenSource(ts))

# And then pass the token source on to the google cloud service you plan to use:

return admin.NewService(context, option.WithTokenSource(ts2))




Do you want these tokensources to cache their access tokens so they don't re-hit the Google Apis all of the time?
Tnen wrap them like this:

newTs := oauth2.ReuseTokenSource(nil, ts)

