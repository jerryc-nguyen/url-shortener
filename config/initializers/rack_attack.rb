Rack::Attack.throttle('limit encode by ip', limit: 10, period: 60) do |request|
  if request.path == '/encode' && request.post?
    request.ip
  end
end

Rack::Attack.throttle('limit decode by ip', limit: 20, period: 60) do |request|
  if request.path == '/decode' && request.post?
    request.ip
  end
end
