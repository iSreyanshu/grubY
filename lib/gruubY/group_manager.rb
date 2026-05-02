module GrubY
  class GroupManager
    DEFAULT_WARN_LIMIT = 3

    def initialize(api, session: nil, warn_limit: DEFAULT_WARN_LIMIT)
      @api = api
      @session = session
      @warn_limit = warn_limit
    end

    def ban(chat_id, user_id, **opts)
      @api.ban_chat_member(chat_id: chat_id, user_id: user_id, **opts)
    end

    def unban(chat_id, user_id, **opts)
      @api.unban_chat_member(chat_id: chat_id, user_id: user_id, **opts)
    end

    def kick(chat_id, user_id, **opts)
      ban(chat_id, user_id, **opts)
      unban(chat_id, user_id)
    end

    def restrict(chat_id, user_id, permissions:, **opts)
      @api.restrict_chat_member(
        chat_id: chat_id,
        user_id: user_id,
        permissions: permissions,
        **opts
      )
    end

    def mute(chat_id, user_id, until_date: nil)
      restrict(
        chat_id,
        user_id,
        permissions: { can_send_messages: false },
        until_date: until_date
      )
    end

    def unmute(chat_id, user_id)
      permissions = {
        can_send_messages: true,
        can_send_audios: true,
        can_send_documents: true,
        can_send_photos: true,
        can_send_videos: true,
        can_send_video_notes: true,
        can_send_voice_notes: true,
        can_send_polls: true,
        can_send_other_messages: true,
        can_add_web_page_previews: true
      }
      restrict(chat_id, user_id, permissions: permissions)
    end

    def promote(chat_id, user_id, **opts)
      @api.promote_chat_member(chat_id: chat_id, user_id: user_id, **opts)
    end

    def demote(chat_id, user_id)
      promote(
        chat_id,
        user_id,
        can_manage_chat: false,
        can_delete_messages: false,
        can_manage_video_chats: false,
        can_restrict_members: false,
        can_promote_members: false,
        can_change_info: false,
        can_invite_users: false,
        can_post_stories: false,
        can_edit_stories: false,
        can_delete_stories: false,
        can_post_messages: false,
        can_edit_messages: false,
        can_pin_messages: false,
        can_manage_topics: false
      )
    end

    def set_member_tag(chat_id, user_id, tag = nil)
      @api.set_chat_member_tag(chat_id: chat_id, user_id: user_id, tag: tag)
    end

    def set_admin_title(chat_id, user_id, title)
      @api.set_chat_administrator_custom_title(
        chat_id: chat_id,
        user_id: user_id,
        custom_title: title
      )
    end

    def set_administrator_title(chat_id, user_id, title)
      set_admin_title(chat_id, user_id, title)
    end

    def set_chat_title(chat_id, title)
      @api.set_chat_title(chat_id: chat_id, title: title)
    end

    def set_chat_description(chat_id, description)
      @api.set_chat_description(chat_id: chat_id, description: description)
    end

    def set_chat_photo(chat_id, photo)
      @api.set_chat_photo(chat_id: chat_id, photo: photo)
    end

    def delete_chat_photo(chat_id)
      @api.delete_chat_photo(chat_id: chat_id)
    end

    def leave_chat(chat_id)
      @api.leave_chat(chat_id: chat_id)
    end

    def set_permissions(chat_id, permissions, **opts)
      @api.set_chat_permissions(chat_id: chat_id, permissions: permissions, **opts)
    end

    def lock(chat_id)
      set_permissions(chat_id, { can_send_messages: false })
    end

    def unlock(chat_id)
      set_permissions(chat_id, { can_send_messages: true })
    end

    def set_slow_mode(chat_id, seconds)
      @api.set_slow_mode(chat_id: chat_id, seconds: seconds)
    end

    def pin(chat_id, message_id, **opts)
      @api.pin_chat_message(chat_id: chat_id, message_id: message_id, **opts)
    end

    def unpin(chat_id, message_id = nil, **opts)
      params = { chat_id: chat_id }.merge(opts)
      params[:message_id] = message_id if message_id
      @api.unpin_chat_message(**params)
    end

    def unpin_all(chat_id)
      @api.unpin_all_chat_messages(chat_id: chat_id)
    end

    def approve_join_request(chat_id, user_id)
      @api.approve_chat_join_request(chat_id: chat_id, user_id: user_id)
    end

    def decline_join_request(chat_id, user_id)
      @api.decline_chat_join_request(chat_id: chat_id, user_id: user_id)
    end

    def get_chat(chat_id)
      @api.get_chat(chat_id: chat_id)
    end

    def get_member(chat_id, user_id)
      @api.get_chat_member(chat_id: chat_id, user_id: user_id)
    end

    def warn(chat_id, user_id, reason: nil)
      key = warn_key(chat_id, user_id)
      current = load_warns(key)
      current += 1
      store_warns(key, current)

      {
        user_id: user_id,
        warns: current,
        limit: @warn_limit,
        reason: reason,
        action: (current >= @warn_limit ? :kick : :none)
      }
    end

    def reset_warns(chat_id, user_id)
      key = warn_key(chat_id, user_id)
      store_warns(key, 0)
    end

    def enforce_warns(chat_id, user_id, reason: nil)
      result = warn(chat_id, user_id, reason: reason)
      return result unless result[:action] == :kick

      kick(chat_id, user_id)
      reset_warns(chat_id, user_id)
      result
    end

    private

    def warn_key(chat_id, user_id)
      "warns:#{chat_id}:#{user_id}"
    end

    def load_warns(key)
      return 0 unless @session

      value = @session.get(key)
      value.is_a?(Hash) ? value["count"].to_i : value.to_i
    end

    def store_warns(key, count)
      return unless @session

      @session.set(key, { "count" => count })
    end
  end
end
