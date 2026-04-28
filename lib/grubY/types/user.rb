require_relative "base_object"

module GrubY
  class User < BaseObject
    fields :id, :is_bot, :first_name, :last_name, :username, :language_code,
      :is_premium, :added_to_attachment_menu, :can_join_groups,
      :can_read_all_group_messages, :supports_inline_queries,
      :can_connect_to_business, :has_main_web_app, :has_topics_enabled,
      :allows_users_to_create_topics, :can_manage_bots

    def archive
      call_raw_api("archiveChats", { chat_ids: [id] })
    end

    def unarchive
      call_raw_api("unarchiveChats", { chat_ids: [id] })
    end

    def block
      call_raw_api("blockUser", { user_id: id })
    end

    def unblock
      call_raw_api("unblockUser", { user_id: id })
    end

    def get_common_chats(offset_chat_id: 0, limit: 100)
      call_raw_api("getCommonChats", { user_id: id, offset_chat_id: offset_chat_id, limit: limit })
    end
  end
end
