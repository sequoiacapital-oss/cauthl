
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "cauthl-gcp"
  spec.version       = File.read(File.expand_path('../../VERSION', __FILE__)).strip
  spec.authors       = ["Caleb Tennis"]
  spec.email         = ["ctennis@sequoiacap.com"]

  spec.summary       = %q{Wraps OIDC auth to GCP STS credentials}
  spec.description   = %q{Wraps OIDC auth to GCP STS credentials}
  spec.homepage      = "https://github.com/sequoiacapital/cauthl"

  spec.metadata = {
    'source_code_uri' => 'https://github.com/sequoiacapital/cauthl',
    'changelog_uri'   => 'https://github.com/sequoiacapital/cauthl'
  }

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency "google-apis-sts_v1", "~> 0.18"
  spec.add_dependency "google-apis-iamcredentials_v1", "~> 0.10"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks", "~> 3.0"
end
