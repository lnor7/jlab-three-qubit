%
% File:   playfid.m
% Date:   23-Jan-03
% Author: I. Chuang <ike@media.mit.edu>
%
% Matlab script to play FID from a spect data structure
%
% Usage:   playfid( fid )
%
% fid - fid from spect structure
%
% /dev/dsp and /dev/aumix should be writable by the user
% the default type is 1 (proton)
%
% Modified 25-Jan-03 by Kenneth Jensen <sanctity@mit.edu>:
%     changed inputs from sd structure to just the fid
% Modified 11-Mar-14 by SPR. changed to use 'aplay' instead of 'play'
% Modified 10-Feb-17 by SPR. changed to use 'audiowrite' instead of 'auwrite'

function playfid(fid)

y = real(fid);
y = y / max(abs(y))*0.99;

%fn = 'fid';
fn = 'fid.wav';

%auwrite(y,1267,16,'linear',fn);
audiowrite(fn,y,1267,'BitsPerSample',16);

%unix(['aplay ' fn '.au >& /dev/null']);
unix(['aplay ' fn '>& /dev/null']);

