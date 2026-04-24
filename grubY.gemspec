Gem::Specification.new do |s|
  s.name        = "grubY"
  s.version     = "0.2.0"
  s.summary     = "Modern Ruby toolkit for Telegram Bot API + TDLib"
  s.authors     = ["Sreyanshu"]
  s.files       = Dir["lib/**/*.rb"] + ["DOCS.md", "docs.html"]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.1"
  s.add_dependency "ffi"
end
