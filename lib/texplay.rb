
# (C) John Mair 2009, under the MIT licence

begin
    require 'rubygems'
rescue LoadError
end

direc = File.dirname(__FILE__)

# include gosu first
require 'rbconfig'
require 'gosu'
require "#{direc}/texplay/version"
require "#{direc}/texplay/patches"

module TexPlay
    class << self
        def on_setup(&block)
            raise "need a block" if !block
            
            @__init_procs__ ||= []
            @__init_procs__.push(block)
        end

        def setup(receiver)
            if @__init_procs__ then
                @__init_procs__.each do |init_proc|
                    receiver.instance_eval(&init_proc)
                end
            end
        end

        def create_image(window, width, height, options={})
          options = {
            :color => :alpha,
            :caching => false,
          }.merge!(options)

          raise ArgumentError, "Height and width must be positive" if height <= 0 or width <= 0
          
          img = Gosu::Image.new(window, EmptyImageStub.new(width, height), :caching => options[:caching])
          img.rect 0, 0, img.width - 1, img.height - 1, :color => options[:color], :fill => true 

          img
        end

        alias_method :create_blank_image, :create_image

        # Image can be :tileable, but it will break if it is tileable AND gets modified after creation.
        def from_blob(window, blob_data, width, height, options={})
          options = {
            :caching => @options[:caching],
            :tileable => false,
          }.merge!(options)

          raise ArgumentError, "Height and width must be positive (received #{width}x#{height})" if height <= 0 or width <= 0

          expected_size = height * width * 4
          if blob_data.size != expected_size
            raise ArgumentError, "Blob data is not of the correct size (expected #{expected_size} but received #{blob_data.size} bytes)"
          end

          Gosu::Image.new(window, ImageStub.new(blob_data, width, height), options[:tileable], :caching => options[:caching])
        end

        def set_options(options = {})
            @options.merge!(options)
        end

        def get_options
            @options
        end

        # default values defined here
        def set_defaults
          @options = {
              :caching => true
          }
        end

        def init
            set_defaults
        end
    end

    module Colors
        Red = [1, 0, 0, 1]
        Green = [0, 1, 0, 1]
        Blue = [0, 0, 1, 1]
        Black = [0, 0, 0, 1]
        White = [1, 1, 1, 1]
        Grey = [0.5, 0.5, 0.5, 1]
        Alpha = [0, 0, 0, 0]
        Purple = [1, 0, 1, 1]
        Yellow = [1, 1, 0, 1]
        Cyan = [0, 1, 1, 1]
        Orange = [1, 0.5, 0, 1]
        Brown = [0.39, 0.26, 0.13, 1]
        Turquoise = [1, 0.6, 0.8, 1]
        Tyrian = [0.4, 0.007, 0.235, 1]
    end
    include Colors

    # extra instance methods defined in Ruby

    # clear an image (with an optional clear color)
    def clear(options = {})
      options = {
        :color => :alpha,
        :fill => true
      }.merge!(options)

      capture {
        rect 0, 0, width - 1, height - 1, options
      
        self
      }
    end
      
end

# Used to create images from blob data.
class ImageStub
    attr_reader :rows, :columns
    
    def initialize(blob_data, width, height)
        @data, @columns, @rows = blob_data, width, height
    end
    
    def to_blob
        @data
    end
end

# Used to create blank images.
# credit to philomory for this class
class EmptyImageStub < ImageStub
    def initialize(width, height)
        super("\0" * (width * height * 4), width, height)
    end
end

# bring in user-defined extensions to TexPlay
direc = File.dirname(__FILE__)
dlext = Config::CONFIG['DLEXT']
begin
    if RUBY_VERSION && RUBY_VERSION =~ /1.9/
        require "#{direc}/1.9/texplay.#{dlext}"
    else
        require "#{direc}/1.8/texplay.#{dlext}"
    end
rescue LoadError => e
    require "#{direc}/texplay.#{dlext}"
end
    
require "#{direc}/texplay-contrib"

# monkey patching the Gosu::Image class to add image manipulation functionality
module Gosu
    class Image

        # bring in the TexPlay image manipulation methods
        include TexPlay

        attr_reader :__window__
        
        class << self 
            alias_method :original_new, :new
            
            def new(*args, &block)

                options = args.last.is_a?(Hash) ? args.pop : {}
                # invoke old behaviour
                obj = original_new(*args, &block)

                prepare_image(obj, args.first, options)
            end
            
            alias_method :original_from_text, :from_text

            def from_text(*args, &block)

                options = args.last.is_a?(Hash) ? args.pop : {}
                # invoke old behaviour
                obj = original_from_text(*args, &block)

                prepare_image(obj, args.first, options)
            end

            def prepare_image(obj, window, options={})
                options = {
                  :caching => TexPlay.get_options[:caching]
                }.merge!(options)
                
                # refresh the TexPlay image cache
                if obj.width <= (TexPlay::TP_MAX_QUAD_SIZE) &&
                    obj.height <= (TexPlay::TP_MAX_QUAD_SIZE) && obj.quad_cached? then
                    obj.refresh_cache if options[:caching]
                end
                
                # run custom setup
                TexPlay.setup(obj)
              
                obj.instance_variable_set(:@__window__, window)

                obj
            end
            
            private :prepare_image
        end

        alias_method :rows, :height
        alias_method :columns, :width             
    end

    class Window
        # Render directly into an existing image, optionally only to a specific region of that image.
        #
        # Since this operation utilises the window's back buffer, the image (or clipped area, if specified) cannot be larger than the
        # window itself. Larger images can be rendered to only in separate sections using :clip_to areas, each no larger
        # than the window).
        #
        # @note *Warning!* This operation will corrupt an area of the screen, at the bottom left corner, equal in size to the image rendered to (or the clipped area), so should be performed in #draw _before_ any other rendering.
        #
        # @note The final alpha of the image will be 255, regardless of what it started with or what is drawn onto it.
        #
        # @example
        #   class Gosu
        #     class Window
        #       def draw
        #         # Always render images before regular drawing to the screen.
        #         unless @rendered_image
        #           @rendered_image = TexPlay.create_image(self, 300, 300, :color => :blue)
        #           render_to_image(@rendered_image) do
        #             @an_image.draw 0, 0, 0
        #             @another_image.draw 130, 0, 0
        #             draw_line(0, 0, Color.new(255, 0, 0, 0), 100, 100, Color.new(255, 0, 0, 0), 0)
        #             @font.draw("Hello world!", 0, 50, 0)
        #           end
        #         end
        #
        #         # Perform regular screen rendering.
        #         @rendered_image.draw 0, 0
        #       end
        #     end
        #   end
        #
        #
        # @param [Gosu::Image] image Existing image to render onto.
        # @option options [Array<Integer>] :clip_to ([0, 0, image.width, image.height]) Area of the image to render into. This area cannot be larger than the window, though the image may be.
        # @option options [Boolean] :clear (true) Whether to clear the screen again after rendering has occurred.
        # @return [Gosu::Image] The image that has been rendered to.
        # @yield to a block that renders to the image.
        def render_to_image(image, options = {})
            raise ArgumentError, "image parameter must be a Gosu::Image to be rendered to" unless image.is_a? Gosu::Image
            raise ArgumentError, "rendering block required" unless block_given?

            options = {
                :clip_to => [0, 0, image.width, image.height],
                :clear => true
            }.merge options

            texture_info = image.gl_tex_info
            tex_name = texture_info.tex_name
            x_offset = (texture_info.left * Gosu::MAX_TEXTURE_SIZE).to_i
            y_offset = (texture_info.top * Gosu::MAX_TEXTURE_SIZE).to_i

            raise ArgumentError, ":clip_to rectangle must contain exactly 4 elements" unless options[:clip_to].size == 4

            left, top, width, height = *(options[:clip_to].map {|n| n.to_i })

            raise ArgumentError, ":clip_to rectangle cannot be wider or taller than the window" unless width <= self.width and height <= self.height
            raise ArgumentError, ":clip_to rectangle width and height must be positive" unless width > 0 and height > 0

            right = left + width - 1
            bottom = top + height - 1

            unless (0...image.width).include? left and (0...image.width).include? right and
                   (0...image.height).include? top and (0...image.height).include? bottom
                raise ArgumentError, ":clip_to rectangle out of bounds of the image"
            end

            # Since to_texture copies an inverted copy of the screen, what the user renders needs to be inverted first.
            scale(1, -1) do
                translate(-left, -top - self.height) do
                    # TODO: Once Gosu is fixed, we can just pass width/height to clip_to
                    clip_to(left, top, width - 1, height - 1) do
                        # Draw over the background (which is assumed to be blank) with the original image texture,
                        # to get us to the base image.
                        image.draw(0, 0, 0)
                        flush

                        # Allow the user to overwrite the texture.
                        yield
                    end

                    # Copy the modified texture back from the screen buffer to the image.
                    to_texture(tex_name, x_offset + left, y_offset + top, 0, 0, width, height)

                    # Clear the clipped zone to black again, ready for the regular screen drawing.
                    if options[:clear]
                        clear = Gosu::Color.new(255, 0, 0, 0)
                        draw_quad(left, top, clear,
                                  right, top, clear,
                                  right, bottom, clear,
                                  left, bottom, clear)
                    end
                end
            end

            image
        end
    end
end

# a bug in ruby 1.8.6 rb_eval_string() means i must define this here (rather than in texplay.c)
class Proc  
    def __context__
        eval('self', self.binding)
    end
end


# initialize TP (at the moment just setting some default settings)
TexPlay.init

