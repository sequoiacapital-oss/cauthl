package cauthl

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestBuildJWTTokenSource verifies the private_key_jwt flow end to end: the
// request shape sent to the token endpoint, the token parsing, and the
// cryptographic validity + claims of the signed client assertion.
func TestBuildJWTTokenSource(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	pkcs8, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	pemKey := pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: pkcs8})

	var gotGrant, gotType, gotScope, gotAssertion string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseForm()
		gotGrant = r.Form.Get("grant_type")
		gotType = r.Form.Get("client_assertion_type")
		gotScope = r.Form.Get("scope")
		gotAssertion = r.Form.Get("client_assertion")
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"access_token":"tok123","token_type":"Bearer","expires_in":3600}`))
	}))
	defer srv.Close()

	ts := BuildJWTTokenSource(context.Background(), "client-abc", pemKey, srv.URL, []string{"scopeA", "scopeB"})
	tok, err := ts.Token()
	if err != nil {
		t.Fatalf("Token() error: %v", err)
	}

	if tok.AccessToken != "tok123" {
		t.Errorf("access token = %q, want tok123", tok.AccessToken)
	}
	if gotGrant != "client_credentials" {
		t.Errorf("grant_type = %q", gotGrant)
	}
	if gotType != clientAssertionType {
		t.Errorf("client_assertion_type = %q", gotType)
	}
	if gotScope != "scopeA scopeB" {
		t.Errorf("scope = %q, want 'scopeA scopeB'", gotScope)
	}

	// The assertion must be a 3-part JWT, RS256-signed by our key.
	parts := strings.Split(gotAssertion, ".")
	if len(parts) != 3 {
		t.Fatalf("assertion is not a JWT: %q", gotAssertion)
	}
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		t.Fatalf("decoding signature: %v", err)
	}
	digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if err := rsa.VerifyPKCS1v15(&key.PublicKey, crypto.SHA256, digest[:], sig); err != nil {
		t.Fatalf("assertion signature invalid: %v", err)
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		t.Fatalf("decoding claims: %v", err)
	}
	var claims map[string]interface{}
	if err := json.Unmarshal(payload, &claims); err != nil {
		t.Fatalf("parsing claims: %v", err)
	}
	if claims["iss"] != "client-abc" || claims["sub"] != "client-abc" {
		t.Errorf("iss/sub = %v/%v, want client-abc", claims["iss"], claims["sub"])
	}
	if claims["aud"] != srv.URL {
		t.Errorf("aud = %v, want %s", claims["aud"], srv.URL)
	}
	if s, _ := claims["jti"].(string); s == "" {
		t.Error("missing jti claim")
	}
	if claims["exp"] == nil {
		t.Error("missing exp claim")
	}
}

func TestBuildJWTTokenSource_ServerError(t *testing.T) {
	key, _ := rsa.GenerateKey(rand.Reader, 2048)
	pkcs8, _ := x509.MarshalPKCS8PrivateKey(key)
	pemKey := pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: pkcs8})

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"error":"invalid_client"}`))
	}))
	defer srv.Close()

	ts := BuildJWTTokenSource(context.Background(), "c", pemKey, srv.URL, nil)
	if _, err := ts.Token(); err == nil {
		t.Fatal("expected error on non-2xx token response, got nil")
	}
}
