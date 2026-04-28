module GrubY
  class Retry
    def self.call(times=3)
      tries = 0
      begin
        yield
      rescue
        tries += 1
        retry if tries < times
        raise
      end
    end
  end
end
