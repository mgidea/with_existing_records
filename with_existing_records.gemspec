$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "with_existing_records/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "with_existing_records"
  s.version     = WithExistingRecords::VERSION
  s.authors     = ["Tom Corley"]
  s.email       = ["tom.corley@goodmeasures.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of WithExistingRecords."
  s.description = "TODO: Description of WithExistingRecords."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.1"

  s.add_development_dependency "sqlite3"
end
