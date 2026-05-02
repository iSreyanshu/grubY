Gem::Specification.new do |s|
  s.name        = "gruubY"
  s.version     = "0.2.2"
  s.summary     = "A Ruby wrapper for Telegram BotAPI and TDLib"
  s.description = "Telegram BotAPI and TDLib toolkit for Ruby, with direct NTgCalls native bindings."
  s.authors     = ["Sreyanshu"]
  s.homepage    = "https://github.com/iSreyanshu/gruubY"
  s.license     = "MIT"
  s.files       = Dir.glob("{lib,config,plugins,example}/**/*").select { |f| File.file?(f) } +
                  %w[README.md LICENSE Rakefile]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.1"
  s.metadata = {
    "homepage_uri" => s.homepage,
    "source_code_uri" => s.homepage
  }
  s.add_dependency "ffi"
end
