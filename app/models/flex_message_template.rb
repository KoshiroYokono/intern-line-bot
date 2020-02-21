require 'pathname'

class FlexMessageTemplate
  def initialize
  end

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

  def generate_flex_template(gifs)
    gifs.map do |gif|
      generate_divisional_flex_template(gif)
    end
  end

  private

  def replace_to_https(url)
    url.sub(/http:/, 'https:')
  end

  def convert_to_jpg(url)
    Pathname(url).sub_ext(".jpg").to_s
  end

end
