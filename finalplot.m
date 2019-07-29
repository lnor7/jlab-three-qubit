pf = calib.pf;

%%%%%%C excitation%%%%%%%%%%%%%%
%{
load("spect-10May19-150438.mat")

p1 = NMRplotSpectra(spect,0,0,[0 0;230 -0.6; 0 0],0);
hold on;

%%%%%%%%%%C1 %%%%%%%%%%%%%%

spect1 = load("spect-10May19-150653.mat");
spect1 = spect1.spect;

p2 = NMRplotSpectra(spect1,0,0,[0,0;125 1.2; 0 0],1);

%%%%%%%%%%C2 %%%%%%%%%%%%%%

spect2 = load("spect-10May19-151020.mat");
spect2 = spect2.spect;
spect2.c1freq = spect2.c1freq+275.08;

p3 = NMRplotSpectra(spect2,0,0,[0,0; 40 -0.07; 0 0],1);

xlim([-200,400])

legend([p1, p2, p3],["Non-selective pulse","C1 selective pulse", "C2 selective pulse"])
%}
%%%%%%%H thermal%%%%%%%%%%%%%%%%
%{
load("spect-10May19-145438.mat")

phc0 = angle(spect.hpeaks(1))*180/pi

phc1 = [0 0 0];
for k=2:4
min_val = spect.hpeaks(k)*exp(-i*phc0*pi/180);
df = pf(1,k) - pf(1,1);
phc1(k-1) = angle(min_val)*180/pi/df;
end

phc1;


[iv,fv] = do_integral(spect.hfreq,spect.hspect,pf(1,:),calib.iwidth,spect.hsfo,[-phc0 0.53]);
spect.hpeaks = iv;

p1 = NMRplotSpectra(spect,0,0,[-phc0 0.53; 0 0; 0 0],0);
xlim([-250,250])
%}

%%%%%%%%H toffoli%%%%%%%%%%%%%%%
%Thermal spectrum

load("spect-10May19-145438.mat")

phc0 = angle(spect.hpeaks(1))*180/pi

phc1 = [0 0 0];
for k=2:4
min_val = spect.hpeaks(k)*exp(-i*phc0*pi/180);
df = pf(1,k) - pf(1,1);
phc1(k-1) = angle(min_val)*180/pi/df;
end

phc1;


[iv,fv] = do_integral(spect.hfreq,spect.hspect,pf(1,:),calib.iwidth,spect.hsfo,[-phc0 0.53]);
spect.hpeaks = iv;

p1 = NMRplotSpectra(spect,0,0,[-phc0 0.53; 0 0; 0 0],0);
hold on;

%Toffoli spectrum
load("spect-13May19-103144.mat")

%phc0 = angle(spect.hpeaks(1))*180/pi;

phc0 = 122;
phc1 = [0 0 0];
for k=2:4
min_val = spect.hpeaks(k)*exp(-i*phc0*pi/180);
df = pf(1,k) - pf(1,1);
phc1(k-1) = angle(min_val)*180/pi/df;
end

phc1;


[iv,fv] = do_integral(spect.hfreq,spect.hspect,pf(1,:),calib.iwidth,spect.hsfo,[-122 1]);
spect.hpeaks = iv;

p2 = NMRplotSpectra(spect,0,0,[-122 6; 0 0; 0 0],1);

xlim([-250, 250])
legend([p1 p2], ["Thermal Spectrum","Toffoli Spectrum"])

angle(spect.hpeaks)*180/pi



%%%%%%%%%C1 toffoli%%%%%%%%%%%%%%%
%Thermal C1 spectrum
%{
load("spect-10May19-145546.mat")

phc0 = angle(spect.c1peaks(1))*180/pi;
hold on;

phc1 = [0 0 0];
for k=2:4
min_val = spect.c1peaks(k)*exp(-i*phc0*pi/180);
df = pf(2,k) - pf(2,1);
phc1(k-1) = angle(min_val)*180/pi/df;
end


%[iv,fv] = do_integral(spect.c1freq,spect.c1spect,pf(2,:),calib.iwidth,spect.c1sfo,[-phc0 -0.3]);
%spect.c1peaks = iv;

p1 = NMRplotSpectra(spect,0,0,[0 0;-phc0 -0.3; 0 0],0);
hold on;

%pulsed C1 spectrum
load("spect-10May19-153504.mat")

phc0 = angle(spect.c1peaks(1))*180/pi;

phc1 = [0 0 0];
for k=2:4
min_val = spect.c1peaks(k)*exp(-i*phc0*pi/180);
df = pf(2,k) - pf(2,1);
phc1(k-1) = angle(min_val)*180/pi/df;
end


[iv,fv] = do_integral(spect.c1freq,spect.c1spect,pf(2,:),calib.iwidth,spect.c1sfo,[-phc0 -0.38]);
spect.c1peaks = iv;

p2 = NMRplotSpectra(spect,0,0,[0 0;-phc0 -0.38; 0 0],1);
xlim([-175, 175])
legend([p1 p2], ["Thermal Spectrum","Toffoli Spectrum"])

angle(spect.c1peaks)*180/pi
%}
