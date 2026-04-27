Gem::Specification.new do |s|
  s.name        = "grubY"
  s.version     = "0.2.0"
  s.summary     = "A Ruby Farmwork for Telegram BotAPI and TDLib"
  s.description = "Telegram BotAPI and TDLib toolkit for Ruby, with optional NTgCalls Python bridge."
  s.authors     = ["Sreyanshu"]
  s.homepage    = "https://github.com/iSreyanshu/grubY"
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
