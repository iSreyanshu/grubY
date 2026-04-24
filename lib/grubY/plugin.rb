module GrubY
  class Plugin
    def self.load(bot, path)
      mod = Module.new
      mod.module_eval(File.read(path), path)

      if mod.respond_to?(:register)
        mod.register(bot)
      else
        raise "Plugin must define register(bot)"
      end
    end
  end
end

