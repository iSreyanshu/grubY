module GrubY
  class Plugin
    def self.load(bot, path)
      absolute_path = File.expand_path(path, Dir.pwd)
      
      unless File.exist?(absolute_path)
        raise "Plugin file not found at: #{absolute_path}"
      end

      mod = Module.new
      mod.module_eval(File.read(absolute_path), absolute_path)

      if mod.const_defined?(:Plugin)
        plugin_mod = mod.const_get(:Plugin)
        if plugin_mod.respond_to?(:register)
          plugin_mod.register(bot)
        else
          raise "Plugin module in #{path} must define register(bot)"
        end
      elsif mod.respond_to?(:register)
        mod.register(bot)
      else
        raise "Plugin in #{path} must define register(bot)"
      end
    end
  end
end