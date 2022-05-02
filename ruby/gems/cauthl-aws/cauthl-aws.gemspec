
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "cauthl-aws"
  spec.version       = File.read(File.expand_path('../../VERSION', __FILE__)).strip
  spec.authors       = ["Caleb Tennis"]
  spec.email         = ["ctennis@sequoiacap.com"]

  spec.summary       = %q{Wraps OIDC auth to AWS STS credentials}
  spec.description   = %q{Wraps OIDC auth to AWS STS credentials}
  spec.homepage      = "https://github.com/sequoiacapital/cauthl"

  spec.metadata = {
    'source_code_uri' => 'https://github.com/sequoiacapital/cauthl',
    'changelog_uri'   => 'https://github.com/sequoiacapital/cauthl'
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cauthl-okta"
  spec.add_dependency "json"
  spec.add_dependency "rest-client"
  spec.add_dependency "aws-sdk-core", "~> 3.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks", "~> 3.0"
end
