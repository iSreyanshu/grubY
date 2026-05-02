module GrubY
  module Raw
    module_function

    def call(api, method, params = {})
      api.raw(method, params)
    end

    def td_call(td_client, query, timeout: 30.0)
      if td_client.respond_to?(:raw)
        td_client.raw(query, timeout: timeout)
      else
        td_client.invoke(query, timeout: timeout)
      end
    end

    def td_call!(td_client, query, timeout: 30.0)
      response = td_call(td_client, query, timeout: timeout)
      if response.is_a?(Hash) && response["@type"] == "error"
        raise StandardError, "TDLib raw error: #{response['message']}"
      end
      response
    end
  end
end
