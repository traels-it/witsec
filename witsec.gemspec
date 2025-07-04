require_relative "lib/witsec/version"

Gem::Specification.new do |spec|
  spec.name = "witsec"
  spec.version = Witsec::VERSION
  spec.authors = ["Nicolai Bach Woller"]
  spec.email = ["woller@traels.it"]
  spec.homepage = "https://github.com/traels-it/witsec"
  spec.summary = "Anonymize your database for dumping"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 8.0"
  spec.add_dependency "sequel", "~> 5.94.0"
  spec.add_dependency "dry-configurable", "~> 1.3.0"
  spec.add_development_dependency "minitest-spec-rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "standard", "~> 1.44"
end
