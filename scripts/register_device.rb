# Registreert een iPhone (UDID) in het Apple Developer-account via de App Store Connect API.
# Nodig voor een ontwikkel-build: die werkt alleen op geregistreerde toestellen.
require "base64"
require "json"
require "net/http"
require "openssl"

udid = ENV.fetch("DEVICE_UDID").strip
name = ENV.fetch("DEVICE_NAME", "iPhone").strip
name = "iPhone" if name.empty?

def b64(data) = Base64.urlsafe_encode64(data, padding: false)

key = OpenSSL::PKey::EC.new(ENV.fetch("ASC_KEY_P8"))
now = Time.now.to_i
header = { alg: "ES256", kid: ENV.fetch("ASC_KEY_ID"), typ: "JWT" }
payload = { iss: ENV.fetch("ASC_ISSUER_ID"), iat: now, exp: now + 1200, aud: "appstoreconnect-v1" }
signing_input = "#{b64(header.to_json)}.#{b64(payload.to_json)}"
der = key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
raw = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2).rjust(32, "\0")[-32..] }.join
token = "#{signing_input}.#{b64(raw)}"

uri = URI("https://api.appstoreconnect.apple.com/v1/devices")
request = Net::HTTP::Post.new(uri, "Authorization" => "Bearer #{token}", "Content-Type" => "application/json")
request.body = { data: { type: "devices", attributes: { name: name, platform: "IOS", udid: udid } } }.to_json
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

case response.code.to_i
when 201
  puts "Toestel '#{name}' geregistreerd."
when 409
  puts "Toestel is al geregistreerd (of het UDID klopt niet): #{response.body}"
else
  warn "Registreren mislukt (#{response.code}): #{response.body}"
  exit 1
end
