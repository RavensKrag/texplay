require 'rake/clean'

$dlext = Config::CONFIG['DLEXT']

CLEAN.include("src/*.#{$dlext}", "src/*.log", "src/*.o", "src/*~", "src/*#*", "src/*.obj", "src/*.def", "src/*.pdb")
CLOBBER.include("**/*.#{$dlext}", "**/*~", "**/*#*", "**/*.log", "**/*.o")

$make_program = if RUBY_PLATFORM =~ /win/ 
                    "nmake"
                else
                    "make"
                end

task :default => [:build]

desc "Build TexPlay"
task :build => :clean do
    puts "(2) building Makefile..."
    chdir("./src/") do
        ruby "extconf.rb"
        puts "(3) building ctexplay.#{$dlext}..."
        sh "#{$make_program}"
        puts "(4) copying ctexplay.#{$dlext} to current directory..."
        cp "ctexplay.#{$dlext}", "../lib" , :verbose => true
        puts "(5) ...done!"
    end
end

SELENE = '/home/john/ruby/projects/selene'
desc "update selene's version of texplay"
task :selene => ["#{SELENE}/lib/texplay.rb", "#{SELENE}/lib/texplay-contrib.rb",
              "#{SELENE}/lib/ctexplay.so"] do
    puts "...done!"
end

file "#{SELENE}/lib/texplay.rb" => "texplay.rb" do |t|
    cp t.prerequisites.first, t.name, :verbose => true
end

file "#{SELENE}/lib/texplay-contrib.rb" => "texplay-contrib.rb" do |t|
    cp t.prerequisites.first, t.name, :verbose => true
end

file "#{SELENE}/lib/ctexplay.#{$dlext}" => "ctexplay.#{$dlext}" do |t|
    cp t.prerequisites.first, t.name, :verbose => true
end
