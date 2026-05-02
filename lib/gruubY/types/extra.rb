require_relative "base_object"
require_relative "chat"
require_relative "user"
require_relative "message_entity"

module GrubY
  class MessageId < BaseObject
    fields :message_id
  end

  class InaccessibleMessage < BaseObject
    fields :chat, :message_id, :date

    def initialize(data)
      super(data)
      @chat = Chat.new(@chat) if @chat.is_a?(Hash)
    end
  end

  class MaybeInaccessibleMessage < BaseObject
    fields :raw

    def initialize(data)
      super({ raw: data })
    end

    def inaccessible?
      @raw.is_a?(Hash) && @raw["date"].to_i.zero?
    end

    def as_inaccessible
      return nil unless inaccessible?

      InaccessibleMessage.new(@raw)
    end
  end

  class TextQuote < BaseObject
    fields :text, :entities, :position, :is_manual

    def initialize(data)
      super(data)
      @entities = Array(@entities).map { |e| MessageEntity.new(e) }
    end
  end

  class ExternalReplyInfo < BaseObject
    fields :origin, :chat, :message_id, :link_preview_options, :animation, :audio,
      :document, :paid_media, :photo, :sticker, :story, :video, :video_note,
      :voice, :has_media_spoiler, :checklist, :contact, :dice, :game,
      :giveaway, :giveaway_winners, :invoice, :location, :poll, :venue

    def initialize(data)
      super(data)
      @chat = Chat.new(@chat) if @chat.is_a?(Hash)
    end
  end

  class MessageOrigin < BaseObject
    fields :type, :date
  end

  class MessageOriginUser < MessageOrigin
    fields :sender_user

    def initialize(data)
      super(data)
      @sender_user = User.new(@sender_user) if @sender_user.is_a?(Hash)
    end
  end

  class MessageOriginHiddenUser < MessageOrigin
    fields :sender_user_name
  end

  class MessageOriginChat < MessageOrigin
    fields :sender_chat, :author_signature

    def initialize(data)
      super(data)
      @sender_chat = Chat.new(@sender_chat) if @sender_chat.is_a?(Hash)
    end
  end

  class MessageOriginChannel < MessageOrigin
    fields :chat, :message_id, :author_signature

    def initialize(data)
      super(data)
      @chat = Chat.new(@chat) if @chat.is_a?(Hash)
    end
  end

  class PhotoSize < BaseObject
    fields :file_id, :file_unique_id, :width, :height, :file_size
  end

  class Animation < BaseObject
    fields :file_id, :file_unique_id, :width, :height, :duration, :thumbnail,
      :file_name, :mime_type, :file_size

    def initialize(data)
      super(data)
      @thumbnail = PhotoSize.new(@thumbnail) if @thumbnail.is_a?(Hash)
    end
  end

  class Audio < BaseObject
    fields :file_id, :file_unique_id, :duration, :performer, :title, :file_name,
      :mime_type, :file_size, :thumbnail

    def initialize(data)
      super(data)
      @thumbnail = PhotoSize.new(@thumbnail) if @thumbnail.is_a?(Hash)
    end
  end

  class Document < BaseObject
    fields :file_id, :file_unique_id, :thumbnail, :file_name, :mime_type,
      :file_size

    def initialize(data)
      super(data)
      @thumbnail = PhotoSize.new(@thumbnail) if @thumbnail.is_a?(Hash)
    end
  end

  class Story < BaseObject
    fields :chat, :id

    def initialize(data)
      super(data)
      @chat = Chat.new(@chat) if @chat.is_a?(Hash)
    end
  end

  class VideoQuality < BaseObject
    fields :file_id, :file_unique_id, :width, :height, :codec, :file_size
  end

  class Video < BaseObject
    fields :file_id, :file_unique_id, :width, :height, :duration, :thumbnail,
      :cover, :start_timestamp, :qualities, :file_name, :mime_type, :file_size

    def initialize(data)
      super(data)
      @thumbnail = PhotoSize.new(@thumbnail) if @thumbnail.is_a?(Hash)
      @cover = Array(@cover).map { |c| PhotoSize.new(c) }
      @qualities = Array(@qualities).map { |q| VideoQuality.new(q) }
    end
  end

  class VideoNote < BaseObject
    fields :file_id, :file_unique_id, :length, :duration, :thumbnail, :file_size

    def initialize(data)
      super(data)
      @thumbnail = PhotoSize.new(@thumbnail) if @thumbnail.is_a?(Hash)
    end
  end

  class Voice < BaseObject
    fields :file_id, :file_unique_id, :duration, :mime_type, :file_size
  end

  class PaidMediaInfo < BaseObject
    fields :star_count, :paid_media
  end

  class PaidMedia < BaseObject
    fields :type
  end

  class PaidMediaPreview < PaidMedia
    fields :width, :height, :duration
  end

  class PaidMediaPhoto < PaidMedia
    fields :photo

    def initialize(data)
      super(data)
      @photo = Array(@photo).map { |p| PhotoSize.new(p) }
    end
  end

  class PaidMediaVideo < PaidMedia
    fields :video

    def initialize(data)
      super(data)
      @video = Video.new(@video) if @video.is_a?(Hash)
    end
  end

  class Contact < BaseObject
    fields :phone_number, :first_name, :last_name, :user_id, :vcard
  end

  class Dice < BaseObject
    fields :emoji, :value
  end

  class PollOption < BaseObject
    fields :persistent_id, :text, :text_entities, :voter_count, :added_by_user,
      :added_by_chat, :addition_date

    def initialize(data)
      super(data)
      @text_entities = Array(@text_entities).map { |e| MessageEntity.new(e) }
      @added_by_user = User.new(@added_by_user) if @added_by_user.is_a?(Hash)
      @added_by_chat = Chat.new(@added_by_chat) if @added_by_chat.is_a?(Hash)
    end
  end

  class InputPollOption < BaseObject
    fields :text, :text_parse_mode, :text_entities
  end

  class PollAnswer < BaseObject
    fields :poll_id, :voter_chat, :user, :option_ids, :option_persistent_ids

    def initialize(data)
      super(data)
      @voter_chat = Chat.new(@voter_chat) if @voter_chat.is_a?(Hash)
      @user = User.new(@user) if @user.is_a?(Hash)
    end
  end

  class Poll < BaseObject
    fields :id, :question, :question_entities, :options, :total_voter_count,
      :is_closed, :is_anonymous, :type, :allows_multiple_answers,
      :allows_revoting, :correct_option_ids, :explanation,
      :explanation_entities, :open_period, :close_date, :description,
      :description_entities

    def initialize(data)
      super(data)
      @question_entities = Array(@question_entities).map { |e| MessageEntity.new(e) }
      @options = Array(@options).map { |o| PollOption.new(o) }
      @explanation_entities = Array(@explanation_entities).map { |e| MessageEntity.new(e) }
      @description_entities = Array(@description_entities).map { |e| MessageEntity.new(e) }
    end
  end

  class ReplyParameters < BaseObject
    fields :message_id, :chat_id, :allow_sending_without_reply, :quote,
      :quote_parse_mode, :quote_entities, :quote_position, :checklist_task_id,
      :poll_option_id
  end
end
