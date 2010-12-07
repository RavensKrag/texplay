direc = File.dirname(__FILE__)

require "#{direc}/../lib/texplay"
require 'ruby_parser'
require 'readline'

class RubyParser
  def self.valid?(code)
    begin
      new.parse(code)
    rescue Racc::ParseError
      return false
    end
    true
  end
end

WIDTH = 640
HEIGHT = 480

class Gosu::Image
  attr_accessor :x, :y

  alias_method :orig_init, :initialize
  def initialize(*args)
    @x = WIDTH / 2
    @y = HEIGHT / 2
    orig_init(*args)
  end
end

class WinClass < Gosu::Window

  class View
    attr_accessor :zoom, :rotate

    def initialize
      @zoom = 1
      @rotate = 0
    end

    def reset
      @zoom = 1
      @rotate = 0
    end
  end
  
  attr_reader :images, :view
  
  def initialize
    super(WIDTH, HEIGHT, false)
    Gosu::enable_undocumented_retrofication

    @images = []
    @view = View.new
    
    @img = TexPlay.create_image(self, 200, 200).tap do |v|
      v.rect 0, 0, v.width - 1, v.height - 1
    end
    
    images << @img
  end

  def create_image(width, height, options={})
    TexPlay.create_image(self, width, height, options)
  end

  def load_image(file)
    Gosu::Image.new(self, file)
  end

  def show_image(image)
    images << image
  end

  def hide_image(image)
    images.delete(image)
  end
  
  def draw
    images.uniq!
    images.each do |v|
      v.draw_rot(v.x, v.y, 1, view.rotate, 0.5, 0.5, view.zoom, view.zoom)
    end
  end

  def update
    eval_string = ""
    while true
      prompt = ""
      if eval_string.empty?
        prompt = "> "
      else
        prompt = "* "
      end
      
      val = Readline.readline(prompt, true)
      eval_string += val

      if val == "!"
        eval_string = ""
        puts "refreshing REPL state"
        break
      end

      exit if val == "quit"
      break if RubyParser.valid?(eval_string)
    end
    begin
      puts "=> #{instance_eval(eval_string).inspect}"
    rescue StandardError => e
      puts "#{e.message}"
    end
  end
end

WinClass.new.show

