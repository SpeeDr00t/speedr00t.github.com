[./ldoce-0.0.2/lib/ldoce/word.rb]

     if mp3?
       unless File.exists? filename
         command = "curl #{mp3_url} -silent > {filename}"
         `{command}`
       end
       `afplay #{filename}`
     end
