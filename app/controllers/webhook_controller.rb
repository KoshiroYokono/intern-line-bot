require 'line/bot'

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
        default_message = {
          type: 'text',
          text: "そのメッセージには対応していないんや。\n・魚\n・深海魚\n・悲しい\n・怒り\nのいずれかを入力してくれ\nスマン m(__)m"
        }
        case event.type
        when Line::Bot::Event::MessageType::Text

          begin
            #Search Endpoint
            text = event.message['text']
            jpg_url = replace_to_https(generate_jpg(text))

            if jpg_url.blank?
              message = default_message
            else
              message = {
                type: 'image',
                originalContentUrl: jpg_url,
                previewImageUrl: jpg_url
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
    url.sub(/.gif/,'.jpg')
  end

 end
