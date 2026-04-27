require_relative "../lib/grubY"

def prompt(label)
  print label
  STDIN.gets.to_s.strip
end

api_id = ENV["TD_API_ID"]&.to_i
api_hash = ENV["TD_API_HASH"].to_s
session_name = ENV.fetch("TD_SESSION_NAME", "default")

abort("Missing TD_API_ID or TD_API_HASH") if api_id.nil? || api_hash.empty?

bundle = GrubY::TDLib::UserSession.build(session_name: session_name)
session_string = GrubY::TDLib::UserSession.encode(
  api_id: api_id,
  api_hash: api_hash,
  database_directory: bundle[:database_directory],
  files_directory: bundle[:files_directory],
  database_encryption_key: bundle[:database_encryption_key],
  session_name: bundle[:session_name]
)

client = GrubY::TDLib::Client.new(
  api_id: api_id,
  api_hash: api_hash,
  database_directory: bundle[:database_directory],
  files_directory: bundle[:files_directory],
  database_encryption_key: bundle[:database_encryption_key],
  tdjson_path: ENV["TDJSON_PATH"],
  td_verbosity: 2,
  workers: 2
)

client.on("updateAuthorizationState") do |update|
  state = update.dig("authorization_state", "@type")

  case state
  when "authorizationStateWaitPhoneNumber"
    loop do
      phone = prompt("Enter phone number (+countrycode...): ")
      next if phone.empty?

      client.set_authentication_phone_number(phone_number: phone)
      break
    end
  when "authorizationStateWaitCode"
    loop do
      code = prompt("Enter login code: ")
      next if code.empty?

      client.check_authentication_code(code)
      break
    end
  when "authorizationStateWaitPassword"
    loop do
      pass = prompt("Enter 2FA password: ")
      next if pass.empty?

      client.check_authentication_password(pass)
      break
    end
  when "authorizationStateWaitOtherDeviceConfirmation"
    link = update.dig("authorization_state", "link")
    puts "Open Telegram > Settings > Devices > Link Desktop Device"
    puts link.to_s
  when "authorizationStateReady"
    me = client.get_me
    puts "Authorized: #{me['first_name']} (id=#{me['id']})"
    puts
    puts "TD_USER_SESSION=#{session_string}"
    puts
    puts "Reuse in Ruby:"
    puts "  cfg = GrubY::TDLib::UserSession.client_kwargs(ENV.fetch('TD_USER_SESSION'))"
    puts "  client = GrubY::TDLib::Client.new(**cfg)"
    client.stop
  end
end

client.start
sleep 0.3 while client.authorized? == false
