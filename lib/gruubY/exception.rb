module GrubY
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class DependencyError < Error; end
end
