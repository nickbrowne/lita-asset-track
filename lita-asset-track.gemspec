Gem::Specification.new do |spec|
  spec.name = "lita-asset-track"
  spec.version = "0.0.1"
  spec.authors = ["Nick Browne"]

  spec.summary = %q{A lita plugin that reports on asset sizes to librato}
  spec.description = %q{A lita plugin that reports on asset sizes to librato}
  spec.homepage = "https://github.com/nickbrowne/lita-asset-track.git"
  spec.license = "MIT"

  spec.metadata = { "lita_plugin_type" => "handler" }

  spec.files = Dir.glob("{lib}/**/**/*")
  spec.bindir = "exe"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "lita"
  spec.add_dependency "lita-timing"
end
