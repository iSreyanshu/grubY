require_relative "base_object"
require_relative "user"

module GrubY
  class MessageEntity < BaseObject
    fields :type, :offset, :length, :url, :user, :language, :custom_emoji_id,
      :unix_time, :date_time_format

    def initialize(data)
      super(data)
      @user = User.new(@user) if @user.is_a?(Hash)
    end
  end
end
