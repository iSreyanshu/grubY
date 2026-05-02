module GrubY
  class Async
    def self.run(&block)
      Thread.new do
        begin
          block.call
        rescue => e
          puts "[ERROR] #{e}"
        end
      end
    end
  end
end
