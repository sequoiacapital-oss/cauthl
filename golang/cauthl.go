package cauthl

import (
	"context"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
)

func BuildClientCredentialsTokenSource(ctx context.Context, clientId string, clientSecret string, tokenURL string, scopes []string) oauth2.TokenSource {
	c := &clientcredentials.Config{
		ClientID:     clientId,
		ClientSecret: clientSecret,
		TokenURL:     tokenURL,
		Scopes:       scopes,
	}

	return c.TokenSource(ctx)
}

func BuildJWTTokenSource(ctx context.Context, clientId string, privateKey []byte, tokenURL string, scopes []string) oauth2.TokenSource {
	c := &clientcredentials.Config{
		ClientID:   clientId,
		PrivateKey: privateKey,
		TokenURL:   tokenURL,
		Scopes:     scopes,
		AuthStyle:  oauth2.AuthStylePrivateKeyJWT,
	}

	return c.TokenSource(ctx)
}
