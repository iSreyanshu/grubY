require "json"
require_relative "types/base_object"

module GrubY
  module RawTypes
    class UpdateGroupCall < GrubY::BaseObject
      fields :group_call
    end

    module_function

    def to_data_json(data)
      {
        "_" => "DataJSON",
        "data" => data.is_a?(String) ? data : JSON.generate(data)
      }
    end

    def input_group_call(id:, access_hash:)
      {
        "_" => "InputGroupCall",
        "id" => id.to_i,
        "access_hash" => access_hash.to_i
      }
    end

    def input_peer_self
      {
        "_" => "InputPeerSelf"
      }
    end

    def join_group_call(call:, params:, muted: false, video_stopped: true, invite_hash: nil, join_as: nil)
      {
        "_" => "JoinGroupCall",
        "call" => call,
        "join_as" => join_as || input_peer_self,
        "params" => params,
        "muted" => !!muted,
        "video_stopped" => !!video_stopped,
        "invite_hash" => invite_hash
      }.compact
    end

    def leave_group_call(call:, source:)
      {
        "_" => "LeaveGroupCall",
        "call" => call,
        "source" => source.to_i
      }
    end

    def update_group_call(payload)
      UpdateGroupCall.new(payload)
    end
  end
end
