birthdays.exe: birthdays.n
	ncc -r:Mono.Posix -out:birthdays.exe birthdays.n

trace: birthdays.exe
	ktrace mono birthdays.exe > /dev/null &&  kdump -E | grep MARK && rm ktrace.out
