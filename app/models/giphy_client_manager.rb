require 'GiphyClient'

class GiphyClientManager
  @@client = GiphyClient::DefaultApi.new
  APIKEY = ENV["GIPHY_API_KEY"]
  API_SEARCH_OPTIONS = {
    limit: 10,
    offset: 0,
    rating: "g",
    lang: "ja",
    fmt: "json"
  }

  def self.client
    @@client
  end

  def message_hash(text)
    begin
      giphy_client = GiphyClientManager.client
      gifs = giphy_client.gifs_search_get(APIKEY, text, API_SEARCH_OPTIONS).data
      if gifs&.count == 10
        flex_message = FlexMessageTemplate.new
        template_array = gifs.map do |gif|
          flex_message.generate_divisional_flex_template(gif)
        end
        hash_flex_template = {
          'type':'carousel',
          'contents': template_array
        }
        return {
          type: 'flex',
          altText: '画像を読み込めませんでした。',
          contents: hash_flex_template
        }
      else
        return {
          type: 'text',
          text: "画像が見つからんかった\nスマンm(__)m"
        }
      end
    rescue GiphyClient::ApiError => e
      puts "Exception when calling DefaultApi->gifs_search_get: #{e}"
    end
  end

end
