# One day of traffic in numbers NimbleHQ can trust (GET /api/metrics/daily).
#
# Only people count. A visit counts when its browser ran our JavaScript and sent
# a page view, which crawlers and scripts don't. Admins never count: any visitor
# who has ever signed in as an admin is left out, signed in or not. "Outside"
# visitors arrived from another site: search, social or a link.
class TrafficReport
  TOP = 5

  def initialize(date)
    @date = date
    @range = date.in_time_zone.all_day
  end

  def as_json(*)
    {
      date: @date.iso8601,
      visitors: visits.distinct.count(:visitor_token),
      visits: visits.count,
      outside_visitors: outside_visits.distinct.count(:visitor_token),
      signups: User.where(created_at: @range).where.not(role: :admin).count,
      top_pages: top(page_views.group(Arel.sql("properties->>'page'")).count, :path, :views),
      top_sources: top(outside_visits.group(:referring_domain).distinct.count(:visitor_token), :source, :visitors)
    }
  end

  private
    def visits
      @visits ||= Ahoy::Visit.where(started_at: @range)
        .where(id: Ahoy::Event.where(name: "$view").select(:visit_id))
        .where.not(visitor_token: Ahoy::Visit.where(user_id: User.admin.select(:id)).select(:visitor_token))
    end

    def outside_visits
      visits.where.not(referring_domain: [ nil, "", *own_domains ])
    end

    def page_views
      Ahoy::Event.where(name: "$view", visit_id: visits.select(:id))
    end

    def own_domains
      host = ENV["APP_HOST"].to_s.delete_prefix("www.")
      host.empty? ? [] : [ host, "www.#{host}" ]
    end

    def top(counts, key, value)
      counts.compact_blank.sort_by { |name, count| [ -count, name.to_s ] }.first(TOP).map { |name, count| { key => name, value => count } }
    end
end
