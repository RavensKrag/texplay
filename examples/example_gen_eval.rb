$LOAD_PATH.unshift File.dirname(File.expand_path(__FILE__))
require 'common'


class W < Gosu::Window
    def initialize
        super(500, 500, false, 20)
        @img = Gosu::Image.new(self, "#{Common::MEDIA}/empty2.png")

        @width = @img.width
        @height = @img.height

        # turn alpha blending and filling on
        @img.set_options :alpha_blend => true, :fill => true
    end
    def draw
        
        # Gen_eval lets us use local instance vars within the block
        # even though the block appears to be getting instance_eval'd
        # for more information see gen_eval.c and object2module.c
        @img.paint {
            rect @width * rand, @height * rand, @width * rand, @height * rand,
            :color => [rand, rand ,rand, rand]
        }  
        
        @img.draw 0, 0,1
    end
end

w = W.new
w.show
        
