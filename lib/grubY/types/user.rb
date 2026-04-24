require_relative "base_object"

module GrubY
  class User < BaseObject
    fields :id, :is_bot, :first_name, :last_name, :username, :language_code,
      :is_premium, :added_to_attachment_menu, :can_join_groups,
      :can_read_all_group_messages, :supports_inline_queries,
      :can_connect_to_business, :has_main_web_app, :has_topics_enabled,
      :allows_users_to_create_topics, :can_manage_bots
  end
end
