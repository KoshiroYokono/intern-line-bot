require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    line_client = LineClientManager.new
    if line_client.validate_signature(body,signature)
      line_client.request(body)
      head :ok
    else
      head 470
    end
  end

 end
