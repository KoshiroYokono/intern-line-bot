class LineClientManager

  def validate_signature(body, signature)
    client.validate_signature(body, signature)
  end

  def request(body)
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
          text = event.message['text']
          giphy_client_manager = GiphyClientManager.new(text)
          message = giphy_client_manager.message_hash
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          client.reply_message(event['replyToken'], default_message)
        end
      end
    }
  end

  private
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
