require 'GiphyClient'

class GiphyClientManager
  attr_reader :text
  APIKEY = ENV["GIPHY_API_KEY"]
  API_SEARCH_OPTIONS = {
    limit: 10,
    offset: 0,
    rating: "g",
    lang: "ja",
    fmt: "json"
  }

  def initialize(text)
    @text = text
  end

  def message_hash
    begin
      giphy_client = GiphyClient::DefaultApi.new
      gifs = giphy_client.gifs_search_get(APIKEY, @text, API_SEARCH_OPTIONS).data
      if gifs
        flex_message = FlexMessageTemplate.new(gifs)
        hash_flex_template = flex_message.generate_flex_template
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
        return {
          type: 'text',
          text: "検索がうまくいかんかった\nスマンm(__)m"
        }
    end
  end

end
