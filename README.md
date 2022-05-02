Cauthl is the Cloud Authentication Library.

We could have picked a better name, but cloud authentication is awful, so why not cauthl?

The various subpackages of cauthl are broken up by cloud provider, and by programming language.

AWS
---

Do you have a place where you have to create AWS IAM user credentials and use in your code? Do you have applications you aren't running in AWS but need the ability to perform AWS API operations? 

This repo provides AWS credential providers that do some wrapping around the OIDC assume-role-with-web-identity-calls that AWS provides.

Now instead of creating IAM users directly, we can create identites directly in our IDP and use them as the credentials in our apps. Those identities can then be authenticated against the IDP, and the resulting token exchanged to AWS to access an AWS role.


GCP
---

Instead of using hardcoded GCP service account credentials, we can leverage our 3rd party identity provider and GCP's Workload Identity Federation to have short lived, constantly rotated credentials useful to our application.


Why cauthl?
-----------

* Added logging/auditing of use in an IDP alongside other identities
* Credential rotation only has to occur in the IDP, not the end application
* If the IDP credentials are leaked, they are much less useful to an attacker who likely will have no idea what they can be used for
* It follows along with our tooling, like Github Actions OIDC auth
