require 'rubygems'
require 'gosu'
require 'texplay'


class W < Gosu::Window
    def initialize
        super(1024, 769, false, 20)
        @img = Gosu::Image.new(self, "empty2.png")
        @gosu = Gosu::Image.new(self, "gosu.png")

        # put a border on the image
        @img.rect 0,0, @img.width - 1, @img.height - 1

        # perform some simple drawing actions 
        @img.line 0,0, @img.width - 1, @img.height - 1, :color => :yellow
        @img.circle 400, 100, 40, :fill => true, :color => [rand, rand, rand, 1]
        @img.rect 200, 300, 300, 400, :fill => true, :color => :red

        # NOTE: chroma_key means NOT to splice in that color (pixels with that color are skipped)
        # (chroma_key_not does the opposite, it skips pixels that do NOT have that color)
        @img.splice @gosu, 210, 330, :chroma_key => :alpha
    end
    
    def draw
        @img.draw 100, 50,1
    end
    
end


w = W.new
w.show
        
