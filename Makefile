%.o: %.s
	as -o $@ $<

%: %.o
	ld $< -o ./bin/$@ -e _start -arch arm64 -L /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem
