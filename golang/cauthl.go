package cauthl

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
	"golang.org/x/oauth2/jws"
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

// clientAssertionType is the RFC 7523 client-assertion type for JWT bearer
// client authentication (private_key_jwt).
const clientAssertionType = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

// BuildJWTTokenSource returns a client_credentials token source that authenticates
// with private_key_jwt (RFC 7523 §2.2): each token request is authenticated by a
// freshly-signed JWT client assertion rather than a client secret.
//
// This is a self-contained implementation against upstream golang.org/x/oauth2 —
// it does NOT depend on a forked oauth2. The returned source caches tokens until
// expiry (oauth2.ReuseTokenSource).
func BuildJWTTokenSource(ctx context.Context, clientId string, privateKey []byte, tokenURL string, scopes []string) oauth2.TokenSource {
	return oauth2.ReuseTokenSource(nil, &jwtTokenSource{
		ctx:        ctx,
		clientID:   clientId,
		privateKey: privateKey,
		tokenURL:   tokenURL,
		scopes:     scopes,
	})
}

type jwtTokenSource struct {
	ctx        context.Context
	clientID   string
	privateKey []byte
	tokenURL   string
	scopes     []string
}

func (s *jwtTokenSource) Token() (*oauth2.Token, error) {
	key, err := parseRSAPrivateKey(s.privateKey)
	if err != nil {
		return nil, fmt.Errorf("cauthl: %w", err)
	}

	jti, err := randJWTID()
	if err != nil {
		return nil, fmt.Errorf("cauthl: %w", err)
	}

	now := time.Now()
	claims := &jws.ClaimSet{
		Iss: s.clientID,
		Sub: s.clientID,
		Aud: s.tokenURL,
		Iat: now.Unix(),
		Exp: now.Add(time.Hour).Unix(),
		// Upstream jws.ClaimSet has no Jti field (the fork added one); carry the
		// RFC 7523 replay-protection id as a private claim instead.
		PrivateClaims: map[string]interface{}{"jti": jti},
	}
	header := &jws.Header{
		Algorithm: "RS256",
		Typ:       "JWT",
	}
	assertion, err := jws.Encode(header, claims, key)
	if err != nil {
		return nil, fmt.Errorf("cauthl: signing client assertion: %w", err)
	}

	v := url.Values{
		"grant_type":            {"client_credentials"},
		"client_assertion_type": {clientAssertionType},
		"client_assertion":      {assertion},
	}
	if len(s.scopes) > 0 {
		v.Set("scope", strings.Join(s.scopes, " "))
	}

	req, err := http.NewRequestWithContext(s.ctx, http.MethodPost, s.tokenURL, strings.NewReader(v.Encode()))
	if err != nil {
		return nil, fmt.Errorf("cauthl: building token request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	resp, err := httpClient(s.ctx).Do(req)
	if err != nil {
		return nil, fmt.Errorf("cauthl: token request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, fmt.Errorf("cauthl: reading token response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("cauthl: token endpoint returned %s: %s", resp.Status, strings.TrimSpace(string(body)))
	}

	var tr struct {
		AccessToken string `json:"access_token"`
		TokenType   string `json:"token_type"`
		ExpiresIn   int64  `json:"expires_in"`
	}
	if err := json.Unmarshal(body, &tr); err != nil {
		return nil, fmt.Errorf("cauthl: parsing token response: %w", err)
	}
	if tr.AccessToken == "" {
		return nil, errors.New("cauthl: token response missing access_token")
	}

	tok := &oauth2.Token{
		AccessToken: tr.AccessToken,
		TokenType:   tr.TokenType,
	}
	if tr.ExpiresIn > 0 {
		tok.Expiry = now.Add(time.Duration(tr.ExpiresIn) * time.Second)
	}
	return tok, nil
}

// httpClient honors an *http.Client stashed on the context via oauth2.HTTPClient
// (matching clientcredentials behavior), falling back to the default client.
func httpClient(ctx context.Context) *http.Client {
	if ctx != nil {
		if hc, ok := ctx.Value(oauth2.HTTPClient).(*http.Client); ok && hc != nil {
			return hc
		}
	}
	return http.DefaultClient
}

// parseRSAPrivateKey accepts a PEM-encoded (PKCS#1 or PKCS#8) RSA private key,
// or the raw DER bytes of one.
func parseRSAPrivateKey(keyBytes []byte) (*rsa.PrivateKey, error) {
	der := keyBytes
	if block, _ := pem.Decode(keyBytes); block != nil {
		der = block.Bytes
	}
	if k, err := x509.ParsePKCS1PrivateKey(der); err == nil {
		return k, nil
	}
	if k, err := x509.ParsePKCS8PrivateKey(der); err == nil {
		rk, ok := k.(*rsa.PrivateKey)
		if !ok {
			return nil, errors.New("private key is not an RSA key")
		}
		return rk, nil
	}
	return nil, errors.New("could not parse private key (expected PEM/DER PKCS#1 or PKCS#8 RSA)")
}

func randJWTID() (string, error) {
	b := make([]byte, 18)
	if _, err := io.ReadFull(rand.Reader, b); err != nil {
		return "", err
	}
	return fmt.Sprintf("%x", b), nil
}
