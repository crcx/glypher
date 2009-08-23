default:
	cd source && fasm -m 120000 glypher.asm ../bin/glypher.exe

clean:
	rm -f `find . | grep \~`
