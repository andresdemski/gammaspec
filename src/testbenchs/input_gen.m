
N=10000;

idx = round(rand(1,20)*N)

signal = zeros(1,N);
signal(idx)= round(rand(1,20)*9+1)
forma = sinc(-4*pi:8*pi/100:4*pi)
signal= filter(forma,1,signal);

signal = signal + abs(min(signal));
signal = signal/max(signal);
signal = signal* (2^12 -1);

fp = fopen('input.dat','w');

for i=1:N
    fprintf(fp,'%.0f\n',signal(i));
end

fclose(fp);