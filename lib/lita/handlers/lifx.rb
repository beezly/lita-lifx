require 'lifx'

module Lita
  module Handlers
    class Lifx < Handler
      route(/^lifx\s+(off|on)\s*(.*)/i,            :power,      help: { "lifx (off|on) [tag]"                 => "Turns off or on bulb (with optional tag)." } )
      route(/^lifx\s+colou?r\s+(\w+)\s*(.*)/i,     :colour,     help: { "lifx colour <colour> [tag]"          => "Sets bulb colour (with optional tag)." } )
      route(/^lifx\s+brightness\s+(\d+)%\s*(.*)/i, :brightness, help: { "lifx brightness <value>% [tag]"      => "Sets bulb brightness (with optional tag)." } )
      route(/^lifx\s+show\s*(.*)/i,                :show,   help: { "lifx show [tag]"                     => "Shows details off bulbs (with optional tag)." } )
      route(/^lifx\s+tags/i,                       :tags,   help: { "lifx tags"                           => "List LIFX tags" } )

      class UnknownTagError < StandardError
        def initialize(tag)
          @tag = tag
        end

        def to_s
          "Unknown Tag: #{@tag}"
        end
      end

      def lights_from_tag(response_tag)
        return @@client.lights if response_tag==""
        if @@client.tags.include? response_tag
          return @@client.lights.with_tag(response_tag) 
        else
          raise UnknownTagError, response_tag
        end
      end

      def power(response)
        command=response.matches[0][0]
        tag=response.matches[0][1]
        begin
          lights=lights_from_tag tag
          lights.send "turn_#{command}"
          response.reply "Turned #{command} lights"
        rescue UnknownTagError => e
          reponse.reply e.to_s
        end
      end

      def show(response)
        begin
          lights=lights_from_tag response.matches[0][0]
          light_description = lights.map {|x| "#{x.label}:#{x.power.to_s}" }.join " "
          response.reply "Lights: #{light_description}"
        rescue UnknownTagError => e
          response.reply e.to_s
        end
      end

      def colour(response)
        begin
          colour=response.matches[0][0]
          lights=lights_from_tag response.matches[0][1]
          lights.set_color LIFX::Color.send(colour)
          response.reply "Colour set to #{colour}"
        rescue UnknownTagError => e
          response.reply e.to_s
        rescue NoMethodError => e
          response.reply "Unknown colour #{colour}"
        end
      end

      def brightness(response)
        begin
          brightness=response.matches[0][0]
          lights=lights_from_tag response.matches[0][1]
          response.reply brightness
          lights.lights.each {|bulb| bulb.set_color(bulb.color.with_brightness(brightness.to_i/100.0)) }
          response.reply "Brightness set to #{brightness}%"
        rescue UnknownTagError => e
          response.reply e.to_s
        end
      end

      def tags(response)
        tags=@@client.tags
        response.reply "LIFX tags are #{tags.join(", ")}"
      end

      @@client = LIFX::Client.lan
      @@client.discover
    end

    Lita.register_handler(Lifx)
  end
end
