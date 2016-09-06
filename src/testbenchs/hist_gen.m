
N=2^13;

M1 = 50*randn(1,N/8);
M1 = M1+ 500;

M2 = 60*randn(1,N/8);
M2 = M2+ 1524;

M3 = 100*randn(1,N/8);
M3 = M3+ 3500;

M4 = 40*randn(1,N/8);
M4 = M4+ 2700;

M5 = 1000*randn(1,N/2);
M5 = M5+2^11;

s = [ M1 M2 M3 M4 M5];

s(s<0 | s>4095)=[];
hist(s,4096);

f = fopen('hist.dat','w');
for i=1:numel(s)
    fprintf(f,'%.0f\n',s(i));
end
fclose(f);