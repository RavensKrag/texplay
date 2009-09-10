TEXPLAY_VERSION = "0.2.3"

Gem::Specification.new do |s|
    s.name = "texplay"
    s.summary = "TexPlay is a light-weight image manipulation framework for Ruby and Gosu"
    s.version = TEXPLAY_VERSION
    s.date = "2009-09-09"
    s.author = "John Mair (banisterfiend)"
    s.email = 'jrmair@gmail.com'
    s.description = s.summary
    s.require_path = 'lib'
    s.add_dependency("gosu",">=0.7.14")
    s.homepage = "http://banisterfiend.wordpress.com/2008/08/23/texplay-an-image-manipulation-tool-for-ruby-and-gosu/"
    s.has_rdoc = false
    s.files = ["Rakefile", "README.markdown", "CHANGELOG",
                "lib/texplay.rb", "lib/texplay-contrib.rb"] +
        Dir.glob("src/*") + Dir.glob("examples/*.rb")  + Dir.glob("examples/media/*")
 
    if RUBY_PLATFORM =~ /mswin/
        s.platform = Gem::Platform::CURRENT
        s.files += ["lib/ctexplay.18.so", "lib/ctexplay.19.so"]
        
    else
        s.platform = Gem::Platform::RUBY
        s.extensions = ["src/extconf.rb"]
    end
end
