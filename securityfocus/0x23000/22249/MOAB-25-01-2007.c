// gcc MOAB-25-01-2007.c -o cfnet-http -framework Carbon

#import <CoreFoundation/CoreFoundation.h>
#import <Carbon/Carbon.h>

int main() {
	SInt32 ret_code;
	UInt8 *myPtr;
	CFDataRef myData;
	CFStringRef url = CFSTR("http://localhost:8080/index.html");
	
	printf("Requesting URL\n");
	
	CFURLRef myURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
	CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, myURL, &myData,
											NULL, NULL, &ret_code);
	
	if (myData != NULL) {
		myPtr = (UInt8 *)CFDataGetBytePtr(myData);
		printf("Data: %s\n", myPtr);
	}
	
	CFRelease(myURL);
	CFRelease(url);
}