require "./lib/version"

Gem::Specification.new do |spec|
  spec.name = "cuban_linx"
  spec.files = Dir["lib/**/*.rb"]
  spec.version = VERSION
  spec.summary = "Chainable functions"
  spec.description = "For procedural ruby"
  spec.authors = ["Ryan Moret"]
  spec.email = "ryancmoret@gmail.com"
  spec.homepage = "https://rubygems.org/gems/cuban_linx"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.add_development_dependency "faker", "2.20.0"
  spec.add_development_dependency "rspec", "3.11.0"
  spec.add_development_dependency "rubcop", "1.27"
  spec.metadata["rubygems_mfa_required"] = "true"
end
