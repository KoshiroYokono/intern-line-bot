require 'line/bot'
require 'GiphyClient'

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
        case event.type
        when Line::Bot::Event::MessageType::Text

          begin
            #Search Endpoint
            text = event.message['text']
            jpg_url = replace_to_https(generate_jpg(text))

            if jpg_url.nil? then
              message = {
                type: 'text',
                text: event.message['text']
              }
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
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end

  def generate_jpg(text)
  stliped = text.strip
    case stliped
    when '魚','fish'
      return Image::FISH
    when '深海魚'
      return Image::DEEPFISH
    when '悲しい','sad'
      return Image::SAD
    when '怒り','angry'
      return Image::ANGRY
    else
      return nil
    end
  end

  def replace_to_https(url)
    return url.sub(/http:/, 'https:')
  end

  def convert_to_jpg(url)
    return url.sub(/.gif/,'.jpg')
  end

 end
