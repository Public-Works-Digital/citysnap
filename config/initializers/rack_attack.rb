# Rack::Attack configuration for rate limiting and security
class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache store
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Safelist ###
  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    Rails.env.development? && [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  ### Throttle Strategies ###

  # Throttle all requests by IP (60rpm)
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login attempts by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email parameter
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email to prevent case bypasses
      req.params["user"]["email"].to_s.downcase.presence if req.params["user"]
    end
  end

  # Throttle password reset attempts
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Throttle admin login attempts more strictly
  throttle("admin/logins/ip", limit: 3, period: 1.minute) do |req|
    if req.path.start_with?("/admin") && req.post?
      req.ip
    end
  end

  # Throttle API/JSON requests
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.end_with?(".json")
  end

  # Exponential backoff for repeated violations
  # Ban IP for 10 minutes after 3 throttle violations
  Rack::Attack.blocklist("fail2ban") do |req|
    # Count throttled requests
    key = "fail2ban:#{req.ip}"

    # Check if currently banned
    if Rails.cache.read("#{key}:banned")
      true
    else
      # Increment counter on throttled request
      if req.env["rack.attack.throttle_data"]
        counter = Rails.cache.increment(key, 1, expires_in: 10.minutes) || 1

        # Ban if exceeded threshold
        if counter > 3
          Rails.cache.write("#{key}:banned", true, expires_in: 10.minutes)
          Rails.logger.warn "[Rack::Attack] Banning IP #{req.ip} for repeated violations"
          true
        else
          false
        end
      else
        false
      end
    end
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after.to_s,
        "X-RateLimit-Limit" => match_data[:limit].to_s,
        "X-RateLimit-Remaining" => "0",
        "X-RateLimit-Reset" => (now + retry_after).to_s
      },
      [ "Too many requests. Please retry after #{retry_after} seconds.\n" ]
    ]
  end

  ### Logging ###
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.info "[Rack::Attack] Throttled #{req.ip} to #{req.path}"
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Blocked #{req.ip} to #{req.path}"
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack
