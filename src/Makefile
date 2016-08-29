
src= $(wildcard *.vhd)
# toplevel = oscope_tb
# toplevel= sigGen_tb
#toplevel= hist_tb
toplevel = comm_oscope_tb

all:
	ghdl -i --std=08 *.vhd ./testbenchs/*.vhd ./testbenchs/OSVVM/*.vhd 
	ghdl -m --std=08 --ieee=synopsys  $(toplevel)
	ghdl -r --std=08 --ieee=synopsys $(toplevel)  --wave=./outputs/out.ghw  --stop-time=1ms
	gtkwave ./outputs/out.ghw ./outputs/savefile.gtkw

isim:
	fuse -top hist_tb -prj hist.prj -o exec
