require_relative "base_object"

module GrubY
  class Chat < BaseObject
    fields :id, :type, :title, :username, :first_name, :last_name,
      :is_forum, :is_direct_messages

    def archive
      call_raw_api("archiveChats", { chat_ids: [id] })
    end

    def unarchive
      call_raw_api("unarchiveChats", { chat_ids: [id] })
    end

    def set_title(title)
      call_api("setChatTitle", { chat_id: id, title: title.to_s })
    end

    def set_description(description)
      call_api("setChatDescription", { chat_id: id, description: description.to_s })
    end

    def set_photo(photo, **opts)
      call_api("setChatPhoto", { chat_id: id, photo: photo }.merge(opts))
    end

    def set_ttl(message_auto_delete_time)
      call_api("setChatMessageAutoDeleteTime", { chat_id: id, message_auto_delete_time: message_auto_delete_time.to_i })
    end

    def ban_member(user_id, **opts)
      call_api("banChatMember", { chat_id: id, user_id: user_id }.merge(opts))
    end

    def unban_member(user_id, **opts)
      call_api("unbanChatMember", { chat_id: id, user_id: user_id }.merge(opts))
    end

    def restrict_member(user_id, permissions:, **opts)
      call_api("restrictChatMember", { chat_id: id, user_id: user_id, permissions: permissions }.merge(opts))
    end

    def promote_member(user_id, **opts)
      call_api("promoteChatMember", { chat_id: id, user_id: user_id }.merge(opts))
    end

    def join
      call_api("joinChat", { chat_id: id })
    end

    def leave
      call_api("leaveChat", { chat_id: id })
    end

    def export_invite_link
      call_api("exportChatInviteLink", { chat_id: id })
    end

    def get_member(user_id)
      call_api("getChatMember", { chat_id: id, user_id: user_id })
    end

    def get_members(**opts)
      call_raw_api("getChatAdministrators", { chat_id: id }.merge(opts))
    end

    def add_members(user_ids)
      ids = Array(user_ids)
      call_api("addChatMembers", { chat_id: id, user_ids: ids })
    end

    def mark_unread
      call_raw_api("markChatUnread", { chat_id: id, is_marked_as_unread: true })
    end

    def set_protected_content(enabled: true)
      call_raw_api("setChatProtectedContent", { chat_id: id, has_protected_content: enabled })
    end

    def unpin_all_messages
      call_api("unpinAllChatMessages", { chat_id: id })
    end

    def mute
      call_raw_api("setChatNotificationSettings", { chat_id: id, mute_for: 2_147_483_647 })
    end

    def unmute
      call_raw_api("setChatNotificationSettings", { chat_id: id, mute_for: 0 })
    end
  end
end
