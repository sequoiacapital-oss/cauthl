An AWS credential provider for doing OIDC authentication to an AWS role.

AWS provides the AssumeRoleWithWebIdentityCredentials provider, which requires a file containing a JWT
to be provided that the API uses to trade for AWS STS credentials. However, *something* has to populate 
the JWT into that file.

This provider is a thin wrapper around that, where we specify some OIDC parameters and let the
class dymamically grab the JWT from the OIDC token endpoint, instead of having to do it in the
background.

This is tested again Okta, but will likely work against any OIDC provider. Each one seems to have
slightly different argument requirements to their token endpoint, so small tweak may be necessary.

Create an okta OIDC application that uses the client_credentials flow. You will get a client id and a client secret.

You will also need an authorization server that defines at least a single custom scope.

Create a token generator. One reference once is available, or build your own:
```
require 'cauthl'

tg = Cauthl::TokenGenerator.new(
  client_id: OKTA_CLIENT_ID,
  client_secret: OKTA_CLIENT_SECRET,
  token_credentials_uri: OKTA_TOKEN_URL,
  scope: []
  )
```

Then, initalize the credentials:
```
  creds = AssumeRoleOIDCClientCredentials.new(
    token_source: tg
    role_arn: 'arn',
    role_session_name: "session-name"
  )
```

Upon credential refresh time, this will make the external call to the OIDC token provider and get the JWT needed for the
traditional AssumeRoleWithWebIdentity call. Then it does that call and populates the credentials.

You can also use the builtin Aws.config construct to set these as that global credentials for your entire application:

```
  Aws.config.update(region: ENV['AWS_REGION'], credentials: creds)
```
