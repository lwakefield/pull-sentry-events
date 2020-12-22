require "http/client"

# usage: SENTRY_TOKEN=xxx crystal run pull_sentry_events.cr -- $issue_id
# if you are self-hosting sentry, you can also set SENTRY_DOMAIN

issue_id = ARGV[0]
sentry_domain = ENV["SENTRY_DOMAIN"]? || "sentry.io"
sentry_token = ENV["SENTRY_TOKEN"]

url =  "https://#{sentry_domain}/api/0/issues/#{issue_id}/events/"
loop do
        res = HTTP::Client.get url, headers: HTTP::Headers{ "Authorization" => "Bearer #{sentry_token}" }
        link_parts = res.headers["link"]
                .split(';')
                .map(&.split(","))
                .flatten.map(&.strip)
                .in_groups_of(4, "")

        next_link = link_parts.find do |parts|
                parts.includes?("rel=\"next\"") && parts.includes?("results=\"true\"")
        end

        puts res.body

        break if next_link.nil?

        url = next_link.not_nil!.find(&.includes?("https://")).not_nil!
        url = url.lchop("<").rchop(">")
end
