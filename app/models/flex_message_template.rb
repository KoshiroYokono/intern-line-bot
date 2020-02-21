require 'pathname'

class FlexMessageTemplate
  attr_reader :gifs
  def initialize(gifs)
    @gifs = gifs
  end

  def generate_flex_template
    template_array = gifs.map do |gif|
      generate_divisional_flex_template(gif)
    end
    hash_flex_template = {
      'type':'carousel',
      'contents': template_array
    }
  end

  private

  def generate_divisional_flex_template(gif)
    url = replace_to_https(convert_to_jpg(gif.images.fixed_height.url))
    uri = replace_to_https(convert_to_jpg(gif.url))
    {
      'type':'bubble',
      'hero':{
        'type':'image',
        'url':url,
        'size':'full',
        'aspectMode':'cover',
        'action':{
          'type':'uri',
          'label':'View details',
          'uri':"#{uri}?openExternalBrowser=1",
          'altUri':{
            'desktop':"#{uri}?openExternalBrowser=1"
          }
       }
      }
    }
  end

  def replace_to_https(url)
    url.sub(/http:/, 'https:')
  end

  def convert_to_jpg(url)
    Pathname(url).sub_ext(".jpg").to_s
  end

end
