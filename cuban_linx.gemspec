require './lib/version'

Gem::Specification.new do |s|
  s.name = "cuban_linx"
  s.files = ["lib/cuban_linx.rb"]
  s.version = VERSION
  s.summary = "Chainable functions"
  s.description = "For procedural ruby"
  s.authors = ["Ryan Moret"]
  s.email = "ryancmoret@gmail.com"
  s.homepage = "https://rubygems.org/gems/cuban_linx"
  s.license = "MIT"
  spec.add_development_dependency "rspec"
end
