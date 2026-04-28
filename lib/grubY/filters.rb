require "set"

module GrubY
  module Filters
    class Filter
      attr_reader :name

      def initialize(name = "Filter", &block)
        @name = name
        @block = block || proc { true }
      end

      def call(*args)
        @block.call(*args)
      end

      def &(other)
        Filter.new("(#{name}&#{other.name})") { |*args| call(*args) && other.call(*args) }
      end

      def |(other)
        Filter.new("(#{name}|#{other.name})") { |*args| call(*args) || other.call(*args) }
      end

      def ~@
        Filter.new("~#{name}") { |*args| !call(*args) }
      end
    end

    class EntityFilter < Filter
      attr_reader :values

      def initialize(name, values = nil, &matcher)
        @values = normalize(values)
        @matcher = matcher
        super(name) do |_filter, _client, update|
          @matcher.call(update, @values)
        end
      end

      def add(value)
        @values.merge(normalize(value))
        self
      end

      def delete(value)
        normalize(value).each { |v| @values.delete(v) }
        self
      end

      def clear
        @values.clear
        self
      end

      private

      def normalize(v)
        Array(v).flatten.compact.map(&:to_s).to_set
      end
    end

    module_function

    def create(func:, name: "CustomFilter", **kwargs)
      Filter.new(name) do |filter, client, update|
        func.call(filter, client, update, **kwargs)
      end
    end

    def all
      Filter.new("all") { true }
    end

    def me
      Filter.new("me") do |_f, _c, u|
        msg = message_from(u)
        msg&.from&.is_bot == false && (msg&.from&.is_self == true || %w[me self].include?(msg&.from&.username.to_s.downcase))
      end
    end

    def bot
      Filter.new("bot") { |_f, _c, u| message_from(u)&.from&.is_bot == true }
    end

    def sender_chat
      Filter.new("sender_chat") { |_f, _c, u| !message_from(u)&.sender_chat.nil? }
    end

    def incoming
      Filter.new("incoming") { |_f, _c, u| message_from(u)&.from&.is_bot != true }
    end

    def outgoing
      Filter.new("outgoing") do |_f, _c, u|
        msg = message_from(u)
        msg && msg.from && (msg.from.is_self == true || msg.from.id == msg.chat&.id)
      end
    end

    def text = has_key_filter("text")
    def reply = Filter.new("reply") { |_f, _c, u| !!(message_from(u)&.reply_to_message || message_from(u)&.reply_to_story) }
    def forwarded = Filter.new("forwarded") { |_f, _c, u| !!message_from(u)&.forward_origin }
    def caption = has_key_filter("caption")
    def self_destruction = has_key_filter("self_destruction")
    def audio = has_key_filter("audio")
    def document = has_key_filter("document")
    def photo = has_key_filter("photo")
    def sticker = has_key_filter("sticker")
    def animation = has_key_filter("animation")
    def game = has_key_filter("game")
    def giveaway = has_key_filter("giveaway")
    def giveaway_winners = has_key_filter("giveaway_winners")
    def gift_code = has_key_filter("gift_code")
    def gift = has_key_filter("gift")
    def users_shared = has_key_filter("users_shared")
    def chat_shared = has_key_filter("chat_shared")
    def video = has_key_filter("video")
    def media_group = has_key_filter("media_group_id")
    def voice = has_key_filter("voice")
    def video_note = has_key_filter("video_note")
    def contact = has_key_filter("contact")
    def location = has_key_filter("location")
    def live_location = Filter.new("live_location") { |_f, _c, u| !!message_from(u)&.location&.dig("live_period") }
    def venue = has_key_filter("venue")
    def web_page = Filter.new("web_page") { |_f, _c, u| !!message_from(u)&.link_preview_options }
    def poll = has_key_filter("poll")
    def dice = has_key_filter("dice")
    def quote = has_key_filter("quote")
    def media_spoiler = has_key_filter("has_media_spoiler")
    def story = has_key_filter("story")
    def new_chat_members = has_key_filter("new_chat_members")
    def left_chat_member = has_key_filter("left_chat_member")
    def new_chat_title = has_key_filter("new_chat_title")
    def new_chat_photo = has_key_filter("new_chat_photo")
    def delete_chat_photo = has_key_filter("delete_chat_photo")
    def group_chat_created = has_key_filter("group_chat_created")
    def supergroup_chat_created = has_key_filter("supergroup_chat_created")
    def channel_chat_created = has_key_filter("channel_chat_created")
    def migrate_to_chat_id = has_key_filter("migrate_to_chat_id")
    def migrate_from_chat_id = has_key_filter("migrate_from_chat_id")
    def pinned_message = has_key_filter("pinned_message")
    def game_high_score = has_key_filter("game_high_score")
    def reply_keyboard = has_key_filter("reply_markup")
    def inline_keyboard = has_key_filter("reply_markup")
    def mentioned = Filter.new("mentioned") { |_f, _c, u| message_from(u)&.entities&.any? { |e| e["type"] == "mention" } }
    def via_bot = has_key_filter("via_bot")
    def admin = Filter.new("admin") { |_f, _c, u| %w[administrator creator].include?(message_from(u)&.chat_member_status.to_s) }
    def video_chat_started = has_key_filter("video_chat_started")
    def video_chat_ended = has_key_filter("video_chat_ended")
    def business = has_key_filter("business_connection_id")
    def video_chat_members_invited = has_key_filter("video_chat_members_invited")
    def successful_payment = has_key_filter("successful_payment")
    def scheduled = has_key_filter("is_scheduled")
    def from_scheduled = has_key_filter("from_scheduled")
    def paid_message = has_key_filter("is_paid_post")
    def linked_channel = has_key_filter("is_automatic_forward")
    def gift_offer = has_key_filter("gift_offer")
    def gift_offer_accepted = has_key_filter("gift_offer_accepted")
    def gift_offer_rejected = has_key_filter("gift_offer_rejected")

    def service
      Filter.new("service") do |_f, _c, u|
        msg = message_from(u)
        next false unless msg

        %w[left_chat_member new_chat_title new_chat_photo delete_chat_photo group_chat_created
           supergroup_chat_created channel_chat_created migrate_to_chat_id migrate_from_chat_id
           pinned_message video_chat_started video_chat_ended video_chat_members_invited successful_payment].any? do |k|
          present_key?(msg, k)
        end
      end
    end

    def media
      Filter.new("media") do |_f, _c, u|
        msg = message_from(u)
        next false unless msg

        %w[audio document photo sticker video animation voice video_note contact location venue poll].any? { |k| present_key?(msg, k) }
      end
    end

    def private
      Filter.new("private") { |_f, _c, u| message_from(u)&.chat&.type == "private" }
    end

    def group
      Filter.new("group") { |_f, _c, u| %w[group supergroup].include?(message_from(u)&.chat&.type) }
    end

    def channel
      Filter.new("channel") { |_f, _c, u| message_from(u)&.chat&.type == "channel" }
    end

    def direct
      Filter.new("direct") { |_f, _c, u| message_from(u)&.chat&.is_direct_messages == true }
    end

    def forum
      Filter.new("forum") { |_f, _c, u| message_from(u)&.chat&.is_forum == true }
    end

    def command(commands, prefixes: "/", case_sensitive: false)
      list = Array(commands).map(&:to_s)
      prefix_list = prefixes.nil? ? [""] : Array(prefixes).map(&:to_s)
      Filter.new("command") do |_f, _c, u|
        msg = message_from(u)
        text = msg&.text.to_s
        next false if text.empty?
        next false unless prefix_list.any? { |p| p.empty? || text.start_with?(p) }

        cmd = text.split(/\s+/, 2).first.to_s
        cmd = cmd.sub(/\A[#{Regexp.escape(prefix_list.join)}]/, "") unless prefix_list.include?("")
        cmd = cmd.split("@", 2).first
        cmd = cmd.downcase unless case_sensitive
        expected = case_sensitive ? list : list.map(&:downcase)
        expected.include?(cmd)
      end
    end

    def regex(pattern, flags: 0)
      reg = pattern.is_a?(Regexp) ? pattern : Regexp.new(pattern.to_s, flags)
      Filter.new("regex") do |_f, _c, u|
        target = if u.respond_to?(:data) && !u.data.to_s.empty?
                   u.data.to_s
                 elsif u.respond_to?(:query)
                   u.query.to_s
                 else
                   msg = message_from(u)
                   msg&.text.to_s.empty? ? msg&.caption.to_s : msg&.text.to_s
                 end
        !!(target =~ reg)
      end
    end

    def user(users = nil)
      require "set"
      EntityFilter.new("user", users) do |u, values|
        msg = message_from(u)
        uid = msg&.from&.id || u&.from&.id
        uname = msg&.from&.username || u&.from&.username
        values.empty? || values.include?(uid.to_s) || values.include?(uname.to_s) || values.include?("me")
      end
    end

    def chat(chats = nil)
      require "set"
      EntityFilter.new("chat", chats) do |u, values|
        msg = message_from(u)
        cid = msg&.chat&.id || u&.chat&.id
        uname = msg&.chat&.username || u&.chat&.username
        values.empty? || values.include?(cid.to_s) || values.include?(uname.to_s) || values.include?("me")
      end
    end

    def topic(topics = nil)
      require "set"
      EntityFilter.new("topic", topics) do |u, values|
        msg = message_from(u)
        tid = msg&.message_thread_id || msg&.direct_messages_topic&.dig("topic_id")
        values.empty? || values.include?(tid.to_s)
      end
    end

    private_class_method

    def has_key_filter(key)
      Filter.new(key) { |_f, _c, u| present_key?(message_from(u), key) }
    end

    def present_key?(obj, key)
      return false unless obj
      value = if obj.respond_to?(:[])
                obj[key]
              elsif obj.respond_to?(key)
                obj.public_send(key)
              end
      !(value.nil? || (value.respond_to?(:empty?) && value.empty?))
    end

    def message_from(update)
      return update if update.is_a?(GrubY::Message)
      return update.message if update.respond_to?(:message)
      return update.edited_message if update.respond_to?(:edited_message)
      return update.business_message if update.respond_to?(:business_message)
      return update.edited_business_message if update.respond_to?(:edited_business_message)

      nil
    end
  end
end
