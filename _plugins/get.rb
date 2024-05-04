require "net/http"
require "json"

module Jekyll
  module GetFilter
    raise "GITHUB_ACTOR not set" unless ENV["GITHUB_ACTOR"]
    raise "GITHUB_TOKEN not set" unless ENV["GITHUB_TOKEN"]

    @@tuples = {}

    def get(rows)
      return @@tuples.values unless @@tuples.empty?

      rows.sort_by { |row| row["repo"].downcase }.each do |row|
        if row["repo"] =~ /^https?:\/\/(?:www\.)?github\.com\/([^\/]*)\/([^\/]*)\/?/
          login, name = $1, $2

          unless @@tuples.key?(login)
            begin
              sleep(1)
              url = URI("https://api.github.com/users/#{login}")
              response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |http|
                request = Net::HTTP::Get.new(url)
                request.basic_auth(ENV["GITHUB_ACTOR"], ENV["GITHUB_TOKEN"])
                http.request(request)
              end
              print "Fetching #{url}... "
              print "200 OK\n" if response.code == "200"
              @@tuples[login] = [JSON.parse(response.body), []]
            rescue => e
              print "#{e}\n"
              puts Net::HTTP.get(URI("https://api.github.com/rate_limit"), "Authorization" => "Basic #{Base64.strict_encode64("#{ENV["GITHUB_ACTOR"]}:#{ENV["GITHUB_TOKEN"]}")}")
              next
            end
          end

          begin
            sleep(1)
            url = URI("https://api.github.com/repos/#{login}/#{name}")
            response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |http|
              request = Net::HTTP::Get.new(url)
              request.basic_auth(ENV["GITHUB_ACTOR"], ENV["GITHUB_TOKEN"])
              http.request(request)
            end
            print "Fetching #{url}... "
            print "200 OK\n" if response.code == "200"
            @@tuples[login][1].push(JSON.parse(response.body))
          rescue => e
            print "#{e}\n"
            puts Net::HTTP.get(URI("https://api.github.com/rate_limit"), "Authorization" => "Basic #{Base64.strict_encode64("#{ENV["GITHUB_ACTOR"]}:#{ENV["GITHUB_TOKEN"]}")}")
          end
        else
          print "Ignoring #{row["repo"]}.\n"
        end
      end
      @@tuples.values
    end
  end
end

Liquid::Template.register_filter(Jekyll::GetFilter)
