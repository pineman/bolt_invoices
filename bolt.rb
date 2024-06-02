require "bundler/setup"

require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "open-uri"
require "date"

class Auth
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
  CLIENT_SECRETS_PATH = "client_secrets.json"
  CREDENTIALS_PATH = "token.yaml"
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  def self.authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    credentials = authorizer.get_credentials("default")
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in your browser:"
      puts url
      puts "Paste the authorization code and press enter:"
      code = gets.chomp
      credentials = authorizer.get_and_store_credentials_from_code(user_id: "default", code: code, base_url: OOB_URI)
    end
    credentials
  end
end

gmail = Google::Apis::GmailV1::GmailService.new
gmail.authorization = Auth.authorize
INVOICE_LINK_REGEX = /https?:\/\/.*?invoice\.taxify\.eu.*?(?=\")/
PRICE_REGEX = /\d+(?:\.\d{2})?€/
DATE_REGEX = /\d{1,2}\s(?:January|February|March|April|May|June|July|August|September|October|November|December)\s\d{4}/
total_map = Hash.new(0)
gmail.list_user_messages("me", max_results: 500, q: "Thanks for choosing Bolt after:2024/05/01 before:2024/05/31").messages.each do |msg|
  msg = gmail.get_user_message("me", msg.id)
  body = msg.payload.body.data.force_encoding("UTF-8")
  price = body[PRICE_REGEX].chomp("€")
  d, m, y = body[DATE_REGEX].split
  d, m = "%02d" % d, "%02d" % Date.strptime(m, "%B").month
  file_name = "../#{y}_#{m}/bolt_#{y}_#{m}_#{d}_#{price}_#{msg.id}.pdf"
  FileUtils.mkdir_p(File.dirname(file_name))
  `curl -sL '#{body[INVOICE_LINK_REGEX]}' > #{file_name} &`
  total_map["#{y}_#{m}"] += price.to_f
end
total_map.keys.sort.each do |k|
  `rm -f ../#{k}/bolt_total_*`
  File.write("../#{k}/bolt_total_#{total_map[k].round 2}.txt", "")
  next if k == "2023_03"
  y, m = k.split("_")
  py, pm = y.to_i, m.to_i - 1
  py, pm = py - 1, 12 if pm == 0
  #previous_left = File.read("../#{py}_#{"%02d" % pm}/left.txt").chomp.to_f
  #unless File.exist?("../#{k}/total.txt")
    #File.write("../#{k}/total.txt", total_map[k])
  #end
  #current_total = File.read("../#{k}/total.txt").chomp.to_f
  #current_left = (previous_left - current_total + 200).round 2
  #File.write("../#{k}/left.txt", current_left.to_s)
end
