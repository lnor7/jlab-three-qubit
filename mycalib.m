pf = evalin('base','calib.pf');
%{
calib_h = NMRRunPulseProg(8,[0 0 ;0 0;0 0],[1;0;0],[0;0;0],[0],0,1);

fcal = fopen("fcal-"+datestr(now,1)+".txt","w");

%%%%%%%%%%%%%%%%%Hydrogen Phase Calibration%%%%%%%%%%%%%%%%%%%%%%
fprintf(fcal,"Hydrogen Phase\n");

phc0 = angle(calib_h.hpeaks(1))*180/pi;
fprintf(fcal,"phc0: %.4f\n",phc0);

min_val = calib_h.hpeaks(4)*exp(-i*phc0*pi/180);
df = pf(1,4) - pf(1,1);
phc1 = angle(min_val)*180/pi/df;
fprintf(fcal,"phc1: %.4f\n",phc1);

phrefh = [-phc0,-phc1];


%%%%%%%%%%%%%%%%%Carbon 1 Phase Calibration%%%%%%%%%%%%%%%%%%%%%%
calib_c1 = NMRRunPulseProg(8,[0 0 ;0 0;0 0],[0;1;0],[0;0;0],[0],0,2);
fprintf(fcal,"Carbon 1 Phase\n");

phc0 = angle(calib_c1.c1peaks(1))*180/pi;
%fprintf(fcal,"phc0: %.4f\n",phc0);

min_val = calib_c1.c1peaks(3)*exp(-i*phc0*pi/180);
df = pf(2,3) - pf(2,1);
phc1_a = (angle(min_val)*180/pi)/df; %add -360 if averaging

min_val = calib_c1.c1peaks(2)*exp(-i*phc0*pi/180);
df = pf(2,2) - pf(2,1);
phc1_b = angle(min_val)*180/pi/df;

%fprintf(fcal,"phc1: %.4f\n",mean([phc1_a phc1_b]));

phrefc1 = [-phc0,-phc1_a];

%%%%%%%%%%%%%%%%%Carbon 2 Phase Calibration%%%%%%%%%%%%%%%%%%%%%%

calib_c2 = NMRRunPulseProg(8,[0 0 ;0 0;0 0],[0;0;1],[0;0;0],[0],0,3);
fprintf(fcal,"Carbon 2 Phase\n");

phc0 = angle(calib_c2.c2peaks(1))*180/pi;
fprintf(fcal,"phc0: %.4f\n",phc0);

min_val = calib_c2.c2peaks(4)*exp(-i*phc0*pi/180);
df = pf(3,4) - pf(3,1);
phc1 = angle(min_val)*180/pi/df;
fprintf(fcal,"phc1: %.4f\n",phc1);

phrefc2 = [-phc0,-phc1];
%}

%phref = [phrefh;phrefc1;phrefc2];

phref = [0 0; 0 0; 0 0];

new_h = NMRRunPulseProg(7.75,phref,[1;0;0],[0;0;0],[0],0,1);

new_c1 = NMRRunPulseProg(7.75,phref,[0;1;0],[0;0;0],[0],0,2);

new_c2 = NMRRunPulseProg(7.75,phref,[0;0;1],[0;0;0],[0],0,3);

%{
fprintf(fcal, "\nJ\n");
[hpeaks,hlocs] = findpeaks(abs(new_spect.hspect),new_spect.hfreq,'NPeaks',2,'MinPeakDistance',100,'MinPeakHeight',0.5e7);
[cpeaks,clocs] = findpeaks(abs(new_spect.cspect),new_spect.cfreq,'NPeaks',2,'MinPeakDistance',100,'MinPeakHeight',1e5);
J_h = hlocs(2)-hlocs(1);
J_c = clocs(2)-clocs(1);
fprintf(fcal,"J from H: %.4f\n",J_h);
fprintf(fcal,"J from C: %.4f\n",J_c);

%{
fprintf(fcal, "PW90 Data\n");
pulses = 1:5:41;
pulse_calib = zeros(4,length(pulses));
for i=1:length(pulses)
    fprintf(fcal, "Pulse %d [us]\n",pulses(i));
    spect = NMRCalib(pulses(i), new_phref);
    hpeaks= findpeaks(abs(spect.hspect),'NPeaks',2,'MinPeakDistance',100,'MinPeakHeight',0.5e7);
    cpeaks = findpeaks(abs(spect.cspect),'NPeaks',2,'MinPeakDistance',100,'MinPeakHeight',1e5);
    pulse_calib(1:2,i) = hpeaks;
    pulse_calib(3:4,i) = cpeaks;
    fprintf(fcal, "\tHydrogen pulses: %.4f, %.4f\n", hpeaks);
    fprintf(fcal, "\tCarbon pulses: %.4f, %.4f\n", cpeaks);
end
%}

fprintf(fcal, "\nPW90 Bisection for H\n");
bounds = [1 10];
peak_bound = pulse_height(bounds(1),new_phref,'h');
fprintf(fcal,"\nPeak height at lower bound: %.4f\n",peak_bound);
pw_h = mean(bounds);
dt = 1;
while dt > 0.4
    pw_h = mean(bounds);
    fprintf(fcal,"\nTesting Pulse Width %.3f (us)\n",pw_h);
    peak_guess = pulse_height(pw_h, new_phref,'h');
    fprintf(fcal,"Peak height: %.4f\n",peak_guess);
    dpeak = peak_guess - peak_bound;
    dt = bounds(2) - bounds(1);
    if dpeak > 0
        fprintf(fcal,"Increasing guess\n");
        bounds(1) = pw_h;
        peak_bound = peak_guess;
        continue
    else
        fprintf(fcal,"Decreasing guess\n");
        bounds(2) = pw_h;
    end
end

fprintf(fcal, "\nPW90 Bisection for C\n");
bounds = [1 15];

peak_bound = pulse_height(bounds(1),new_phref,'c');
fprintf(fcal,"\nPeak height at lower bound: %.4f\n",peak_bound);
pw_c = mean(bounds);
dt = 1;
while dt > 0.4
    pw_c = mean(bounds);
    fprintf(fcal,"\nTesting Pulse Width %.3f (us)\n",pw_c);
    peak_guess = pulse_height(pw_c, new_phref,'c');
    fprintf(fcal,"Peak height: %.4f\n",peak_guess);
    dpeak = peak_guess - peak_bound;
    dt = bounds(2) - bounds(1);
    if dpeak > 0
        fprintf(fcal,"Increasing guess\n");
        bounds(1) = pw_c;
        peak_bound = peak_guess;
        continue
    else
        fprintf(fcal,"Decreasing guess\n");
        bounds(2) = pw_c;
    end
end
%}

%{
fprintf(fcal,"\n Additional tests \n");
peak_guess = pulse_height(7.5, new_phref,'c');
fprintf(fcal,"C 7.5mu Peak height: %.4f\n",peak_guess);
peak_guess = pulse_height(7.5, new_phref,'h');
fprintf(fcal,"H 7.5mu Peak height: %.4f\n",peak_guess);

function [peak] = pulse_height(pw, phref, nuc)
    if nuc == 'h'
        spect = NMRRunPulseProg([pw,pw], phref, [1;0], [0;0],[0],0,1);
        peak = real(spect.hpeaks(1));
    else
        spect = NMRRunPulseProg([pw,pw], phref, [0;1], [0;0],[0],0,2);
        peak = real(spect.cpeaks(1));
    end
end
%}