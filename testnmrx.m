%
% File:   testnmrx.m
% Date:   21-Jan-03
% Author: I. Chuang <ichuang@mit.edu>
%
% Test the network linkup to the netnmr2 process running under xwin-nmr
%
% Edit: 11-Mar-14 (SPR) Removed *1e6 from SF01 get line

fprintf(1,'Testing network connection to the spectrometer...');

sfo        = str2num(nmrx('getparm d SFO1'));
swh        = str2num(nmrx('getparm d SW_h'));

fprintf(1,'\n');
fprintf(1,'Spectrometer SFO1 frequency is set to %f MHz\n',sfo);
fprintf(1,'  and the spectral width of the acquisition window is %f Hz\n',swh);
