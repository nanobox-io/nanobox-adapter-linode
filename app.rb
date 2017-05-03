require 'sinatra'
require 'json'

if development?
  require 'pry'
end

Dir["./lib/*.rb"].each { |file| require file }

configure do
  set :bind, '0.0.0.0'
end

configure :development do
  # http://www.sinatrarb.com/intro.html#Error%20Handling
  # From what I can tell, this doesn't work. The error block doesn't get called.
  set :show_exceptions, :after_handler
end

before do
  if settings.production?
    redirect request.url.sub('http', 'https') unless request.secure?
  end
  content_type 'application/json'
  request.body.rewind
  request_body = request.body.read
  @request_payload = JSON.parse(request_body) unless request_body.empty?
end

get '/' do
  content_type 'text/html'
  'Linode API Adapter for Nanobox. ' \
  'source: https://github.com/nanobox-io/nanobox-adapter-linode'
end

get '/meta' do
  Meta.attrs.to_json
end

get '/catalog' do
  Catalog.regions.to_json
end

post '/verify' do
  client.verify
  status 200
end

get '/servers' do
  client.servers.to_json
end

get '/servers/:id' do
  client.server(params['id']).to_json
end

post '/servers' do
  status 201
  server_id = client.server_order(@request_payload)
  { id: server_id.to_s }.to_json
end

delete '/servers/:id' do
  client.server_delete(params['id'])
  status 200
end

patch '/servers/:id/reboot' do
  client.server_reboot(params['id'])
  status 200
end

patch '/servers/:id/rename' do
  client.server_rename(params['id'], @request_payload['name'])
  status 200
end

# https://www.linode.com/api
# 0: ok
# 1: Bad request
# 2: No action was requested
# 3: The requested class does not exist
# 4: Authentication failed
# 5: Object not found
# 6: A required property is missing for this action
# 7: Property is invalid
# 8: A data validation error has occurred
# 9: Method Not Implemented
# 10: Too many batched requests
# 11: RequestArray isn't valid JSON or WDDX
# 12: Batch approaching timeout. Stopping here.
# 13: Permission denied
# 14: API rate limit exceeded
# 30: Charging the credit card failed
# 31: Credit card is expired
# 40: Limit of Linodes added per hour reached
# 41: Linode must have no disks before delete
# 42: StackScript limit has been reached
error do
  e_message = env['sinatra.error'].message
  # e.g. "Errors completing request [account.info] @ [https://api.linode.com/] with data [{}]:
  # - Error #4 - Authentication failed.  (Please consult https://www.linode.com/api/account/account.info)"
  match = /Error\s#(?<code>\d+)\s-/.match(e_message)
  e_code = match[:code].to_i if match && match[:code]
  case e_code
  when 1
    status 400
  when 4
    status 401
  when 30, 31
    status 402
  when 13
    status 403
  when 5
    status 404
  when 2, 3, 6, 7, 8, 9, 10, 11, 12, 14, 40, 41, 42
    status 422
  else
    status 500
  end
  body "Linode error: #{e_message}"
end

def client
  Client.new(request.env['HTTP_AUTH_API_KEY'])
end
