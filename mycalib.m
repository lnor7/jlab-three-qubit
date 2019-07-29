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
