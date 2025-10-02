# Configure session store for production stability
# This ensures sessions persist properly across Fly.io machine restarts
Rails.application.config.session_store :cookie_store,
  key: "_citysnap_session",
  same_site: :lax,
  secure: Rails.env.production?,
  expire_after: 2.weeks
