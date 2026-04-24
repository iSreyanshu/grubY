require_relative "base_object"

module GrubY
  class Chat < BaseObject
    fields :id, :type, :title, :username, :first_name, :last_name,
      :is_forum, :is_direct_messages
  end
end
