require 'rubygems'
require 'common'
require 'gosu'
require 'texplay'


class W < Gosu::Window
    def initialize
        super(1024, 769, false, 20)
        @img = Gosu::Image.new(self, "#{Common::MEDIA}/sunset.png")
    end
    
    def draw
        x = (@img.width - 100/2) * rand 
        y = (@img.height - 100/2) * rand 

        @img.rect x, y, x + 50, y + 50, :fill => true, :color_control => { :mult => [0.9, 0.7, 0.4, 1] }

        @img.draw 100, 50,1
    end
    
end


w = W.new
w.show
        
