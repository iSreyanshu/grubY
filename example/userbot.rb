require_relative "../lib/gruubY"

begin
  require "io/console"
rescue LoadError
end

begin
  require "rqrcode"
rescue LoadError
  RQRCode = nil
end

def clear_print
  print "\e[2J\e[f"
end

def prompt(label)
  print label
  STDIN.gets.to_s.strip
end

api_id = ENV["TD_API_ID"]&.to_i
api_hash = ENV["TD_API_HASH"]

abort("Missing TD_API_ID or TD_API_HASH") if api_id.nil? || api_hash.to_s.empty?

client = GrubY::TDLib::Client.new(
  api_id: api_id,
  api_hash: api_hash,
  database_directory: "storage/tdlib-userbot",
  files_directory: "storage/tdlib-userbot/files",
  tdjson_path: ENV["TDJSON_PATH"],
  td_verbosity: 2,
  options: {
    "ignore_background_updates" => false
  },
  workers: 4,
  default_handler_timeout: 15
)

client.on("updateAuthorizationState") do |update|
  state = update.dig("authorization_state", "@type")

  case state
  when "authorizationStateWaitPhoneNumber"
    loop do
      input = prompt('Enter phone number or "qr": ')
      next if input.empty?

      if input.downcase == "qr"
        res = client.request_qr_code_authentication
        if res["@type"] == "error"
          puts "Error: #{res['message']}"
          next
        end
      else
        res = client.set_authentication_phone_number(phone_number: input)
        if res["@type"] == "error"
          puts "Error: #{res['message']}"
          next
        end
      end

      break
    end
  when "authorizationStateWaitOtherDeviceConfirmation"
    link = update.dig("authorization_state", "link")
    clear_print
    puts "Scan QR from Telegram mobile app -> Settings -> Devices -> Link Desktop Device"
    puts
    puts link

    if RQRCode
      puts
      qr = RQRCode::QRCode.new(link)
      qr.modules.each do |row|
        puts row.map { |m| m ? "##" : "  " }.join
      end
    else
      puts "\nInstall `rqrcode` gem for terminal QR rendering."
    end
  when "authorizationStateWaitCode"
    loop do
      code = prompt("Enter login code: ")
      next if code.empty?

      res = client.check_authentication_code(code)
      if res["@type"] == "error"
        puts "Error: #{res['message']}"
        next
      end
      break
    end
  when "authorizationStateWaitPassword"
    clear_print
    hint = update.dig("authorization_state", "password_hint")
    loop do
      pass = prompt("Enter 2FA password (hint: #{hint}): ")
      next if pass.empty?

      res = client.check_authentication_password(pass)
      if res["@type"] == "error"
        puts "Error: #{res['message']}"
        next
      end
      break
    end
  when "authorizationStateReady"
    me = client.get_me
    clear_print
    puts "Logged in as #{me['first_name']} (ID: #{me['id']})"
  end
end

client.on_message do |message|
  next unless message.dig("content", "@type") == "messageText"
  next unless message["is_outgoing"]

  text = message.dig("content", "text", "text").to_s
  next unless text == "!hi"

  client.edit_message_text(
    chat_id: message["chat_id"],
    message_id: message["id"],
    input_message_content: {
      "@type" => "inputMessageText",
      "text" => { "@type" => "formattedText", "text" => "Hey, This is from GrubY TDLib Userbot!" }
    }
  )
end

client.run
