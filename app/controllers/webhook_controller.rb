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
        default_message = {
          type: 'text',
          text: "そのメッセージには対応していないんや。\nスマン m(__)m"
        }
        case event.type
        when Line::Bot::Event::MessageType::Text

          begin
            #Search Endpoint
            text = event.message['text']

            api_instance = GiphyClient::DefaultApi.new
            api_key = ENV["GIPHY_API_KEY"]

            opts = {
              limit: 10,
              offset: 0,
              rating: "g",
              lang: "ja",
              fmt: "json"
            }

            template_json = {
              'type':'bubble',
              'hero':{
                'type':'image',
                'url':'',
                'size':'full',
                'aspectMode':'cover',
                'action':{
                  'type':'uri',
                  'label':'View details',
                  'uri':'',
                  'altUri':{
                    'desktop':''
                  }
                }
              }
            }

            result = api_instance.gifs_search_get(api_key, text, opts)
            gifs = result.data
            if gifs&.count == 10

            template_array = gifs.map do |gif|
              {
                'type':'bubble',
                'hero':{
                  'type':'image',
                  'url':gif.images.fixed_height.url,
                  'size':'full',
                  'aspectMode':'cover',
                  'action':{
                    'type':'uri',
                    'label':'View details',
                    'uri':gif.url+'?openExternalBrowser=1',
                    'altUri':{
                      'desktop':"#{gif.url}?openExternalBrowser=1"
                    }
                  }
                }
              }
            end

              hash_flex_template = {
                'type':'carousel',
                'contents': template_array
              }

              message = {
                type: 'flex',
                altText: '代官テキスト',
                contents: hash_flex_template
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

  def replace_to_https(url)
    url.sub(/http:/, 'https:')
  end

  def convert_to_jpg(url)
    Pathname(url).sub_ext(".jpg").to_s
  end

 end
