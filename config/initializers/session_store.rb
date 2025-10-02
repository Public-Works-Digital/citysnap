# Configure session store for production stability
# Use database-backed sessions to ensure sessions work across multiple Fly.io machines
# This solves the issue where requests are load-balanced to different machines
Rails.application.config.session_store :active_record_store,
  key: "_citysnap_session",
  same_site: :lax,
  secure: Rails.env.production?,
  expire_after: 2.weeks
