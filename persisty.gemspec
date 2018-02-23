# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persisty/version'

Gem::Specification.new do |spec|
  spec.name          = "persisty"
  spec.version       = Persisty::VERSION
  spec.authors       = ["Victor Alexandre"]
  spec.email         = ["victor.alexandrefs@gmail.com"]

  spec.summary       = %q{Object-Document Mapping with repositories and Unit of Work.}
  spec.description   = %q{An alternative to Object-Document Mapping using patterns like Data Mapper and Unit of Work, to provide a clean and simple struture to persist Ruby objects.}
  spec.homepage      = "https://github.com/docStonehenge/persisty"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.15"

  spec.add_runtime_dependency 'mongo', '~> 2.5', '>= 2.5.1'
  spec.add_runtime_dependency 'dotenv', '~> 2.2', '>= 2.2.1'
end
