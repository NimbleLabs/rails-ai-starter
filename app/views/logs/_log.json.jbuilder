json.extract! log, :id, :level, :source, :message, :error_class, :fingerprint, :occurrences,
              :last_seen_at, :resolved_at, :notified_at, :request_id, :path, :created_at, :updated_at
json.title log.title
json.resolved log.resolved?
json.user(log.user ? { id: log.user.id, name: log.user.name, email: log.user.email } : nil)
if local_assigns[:full]
  json.backtrace log.backtrace
  json.context log.context
end
