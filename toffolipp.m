%pulses on hydrogen
%for original gate, first element was 2, last element was 1
pp1 = [0.5 0 0 0 1 1 1.5];
pp1 = [pp1 0 0 0 1 1 0.5];
pp1 = [pp1 0 0 0 1 1 0.5];

%pulses on carbon 1
pp2 = [0 1 2 1 0 0 0];
pp2 = [pp2 0 0 0 0 0 0];
pp2 = [pp2 1 2 1 0 0 0];

%pulses on carbon 2
pp3 = [0 0 0 0 0 0 0];
pp3 = [pp3 1 2 1 0 0 0];
pp3 = [pp3 0 0 0 0 0 0];

%pulses with readout on hydrogen
pulses = [pp1 1;pp2 0;pp3 0].*2;

%phases on hydrogen
%for original gate, last element was 3
ph1 = [1 0 0 0 3 0 1];
ph1 = [ph1 0 0 0 3 0 1];
ph1 = [ph1 0 0 0 3 0 1];

%phases on carbon 1
ph2 = [0 0 0 3 0 0 0];
ph2 = [ph2 0 0 0 0 0 0];
ph2 = [ph2 0 0 3 0 0 0];

%phases on carbon 2
ph3 = [0 0 0 0 0 0 0];
ph3 = [ph3 0 0 3 0 0 0];
ph3 = [ph3 0 0 0 0 0 0];

%phases with readout
phases = [ph1 0;ph2 0;ph3 0];

%delays
tau12 = 1000/(2*197);
tau13 = 1000/(2*17);

delays = [0 tau12 0 tau12 0 0 0];
delays = [delays tau13 0 tau13 0 0 0];
delays = [delays tau12 0 tau12 0 0 0 0];

%arguments: pw, phref (set in another program), pulses, phases, delays,
%tavg, nuc
htoffoli = NMRRunPulseProg(7.75/2,phref,pulses,phases,delays,0,1);