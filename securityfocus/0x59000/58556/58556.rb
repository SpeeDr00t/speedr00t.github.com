command_wrap.rb-7- def self.capture (url, target)

command_wrap.rb-8- command = 
CommandWrap::Config::Xvfb.command(File.dirname(__FILE__) + 
"/../bin/CutyCapt 
--min-width=1024 --min-height=768 --url={url} --out={target}") 
command_wrap.rb:9: `#{command}`
command_wrap.rb-10- end
command_wrap.rb-11-
--
command_wrap.rb-72- command = 
CommandWrap::Config::Xvfb.command(File.dirname(__FILE__) + 
"/../bin/wkhtmltopdf --quiet 
--print-media-type #{source} #{params} #{target}") command_wrap.rb-73-
command_wrap.rb:74: `#{command}`
