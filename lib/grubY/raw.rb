module GrubY
  module Raw
    def self.call(api, method, params={})
      api.raw(method, params)
    end
  end
end

