An GCP credential provider for doing OIDC authentication to an GCP service account.

GCP has a Workload Identity Federation setup that allows you to trade a defined access_token
in for a credential that's bound to the service account.

This library is a set of wrappers to help facilitate that. You will first need to setup and define a WIF
pool in your GCP environment. You will also need a service account that has been properly permissioned to allow
the use of that workload identity pool.

First, much like the AWS provider, we need to create an access token generator tied to our IDP. You can use
the reference example or build your own.

```
require 'cauthl'

tg = Cauthl::AccessTokenGenerator.new(
  client_id: OKTA_CLIENT_ID,
  client_secret: OKTA_CLIENT_SECRET,
  token_credentials_uri: OKTA_TOKEN_URL,
  scope: []
  )
```

Next we create a GCP STS Token generator:

```
  tg = Cauthl::Gcp::StsToken.new(
    token_source: tg,
    pool: "//iam.googleapis.com/projects/PROJECT_ID/locations/global/workloadIdentityPools/POOL_NAME/providers/PROVIDER_NAME
  )
```

Then create the federated token generator:
```
  ft = Cauthl::Gcp::FederatedToken.new(tg, 
    service_account: "service-account-name@service-account-project.iam.gserviceaccount.com", 
    scopes: ["https://www.googleapis.com/auth/calendar"])  # This is a sample scope, based on what the service account will need to do
```

You can then use the token generator as the GCP Service authorizer:

```
  @service = Google::Apis::CalendarV3::CalendarService.new
  @service.authorization = ft
```

If you need to access Google Workspace via domain wide delegation, then you'll need an additional step of impersonatng a user
```
  it = Cauthl::Gcp::ImpersonatedToken.new(ft,
    service_account:  "service-account-name@service-account-project.iam.gserviceaccount.com",
    impersonated_user: "youruser@yourdomain.com",
    scopes: ["https://www.googleapis.com/auth/calendar"])