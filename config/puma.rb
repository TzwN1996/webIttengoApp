# workers ENV.fetch("WEB_CONCURRENCY", 1)
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count
port ENV.fetch("PORT", 4567)
environment ENV.fetch("RACK_ENV", "development")
