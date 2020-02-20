require 'line/bot'
require 'GiphyClient'
require 'pathname'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        message_text = <<~'EOS'
          そのメッセージには対応していないんや。
          ・魚
          ・深海魚
          ・悲しい
          ・怒り
          のいずれかを入力してくれ
          スマン m(__)m
        EOS
        default_message = {
          type: 'text',
          text: "#{message_text.chomp}"
        }
        case event.type
        when Line::Bot::Event::MessageType::Text

          begin
            #Search Endpoint
            text = event.message['text']
            jpg_url = replace_to_https(generate_jpg(text))

            api_instance = GiphyClient::DefaultApi.new
            api_key = ENV["GIPHY_API_KEY"]

            opts = {
              limit: 1,
              offset: 0,
              rating: "g",
              lang: "ja",
              fmt: "json"
            }

            result = api_instance.gifs_search_get(api_key, text, opts)
            gif = result.data[0]
            if gif
              message = {
                type: 'image',
                originalContentUrl: replace_to_https(convert_to_jpg(gif.images.fixed_height.url)),
                previewImageUrl: replace_to_https(convert_to_jpg(gif.images.preview_gif.url))
              }
            else
              message = {
                type: 'text',
                text: "画像が見つからんかった\nスマンm(__)m"
              }
            end

          rescue GiphyClient::ApiError => e
            puts "Exception when calling DefaultApi->gifs_search_get: #{e}"
          end

          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
           client.reply_message(event['replyToken'], default_message)
        end
      end
    }
    head :ok
  end

  def generate_jpg(text)
    stripped_text = text.strip
    case stripped_text
    when '魚','fish','さかな','サカナ'
      return Image::FISH
    when '深海魚','しんかいぎょ','シンカイギョ'
      return Image::DEEPFISH
    when '悲しい','sad'
      return Image::SAD
    when '怒り','angry'
      return Image::ANGRY
    else
      return ""
    end
  end

  def replace_to_https(url)
    url.sub(/http:/, 'https:')
  end

  def convert_to_jpg(url)
    Pathname(url).sub_ext(".jpg").to_s
  end

 end
