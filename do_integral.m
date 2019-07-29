%
% File: do_integral.m
% Date: 23-Jan-03
% Author: Kenneth Jensen <sanctity@mit.edu> 
%         (taken from code by Ike Chuang)
%
% Usage:  [iv,fv] = do_integral(fdat,spect,pf,iw,sfo,phases)
%
% Where:
%
% fdat    - frqeuency axis (relative to sfo) units of [Hz]
% spect   - spectral data (complex-valued) [Arb]
% pf      - 2-D array of frequencies where peaks are located, in [Hz]
% iw      - half of the integration width for a peak, in [Hz]
% sfo     - center frequency of the data [Hz]
% phases  - optional argument giving additional phase corrections to
%           apply to the spectral data before integration
% 
% iv      - row vector of complex integral values (one for each peak location)
% fv      - frequency of peaks which were integrated, relative to sfo [Hz]
% 
% This function integrates the peaks in a spectral data set, given
% the spectral data, and where the peaks are, to integrate.  The elments
% of pf are frequencies, specifying center values for the peaks.  These
% values are calibrated by a Junior Lab staff member, and should not
% be changed for regular use.  Typically, pf has values such as:
%
% pf = [ 200.131499 200.131746 ; 0.50326 0.40328 ] * 1e6
% 
% Note that the function only returns integral values for peaks with 
% frequencies located in the spectrum handed to the function.  For peaks
% outside of the fdat given, the corresponding iv entries are zero.
%
% Note that pf is usually read from the global variable calib.pf.
% To determine the peak frequencies to use, zoom in on the peaks by hand
% (zoom on) and use ginput to determine the peak locations.  Store these
% values (as absolute frequencies!) in calib.pf.  Thus, for example,
% 
%       calib.pf(1:2) = [-105.28 111.35] + spect.hsfo
%
% By convention, for Junior Lab, pf has two rows, with the
% two proton peak locations followed by the two carbon peak locations.
%
% Note that trapezoidal integration is done.  This function should really
% not be relied upon, however, for peak integrals, since the right thing
% to do is to fit the data to lorentzians and compute the area that way.
% This is why the peak integrals returned by this function do not have
% error bars.
%
% 10-Feb-06 I. Chuang and S. Sewell: fixed bug in which the spectrum
% was multiplied by the phase over and over inside the loop over peak
% frequencies.  This should only have been done once, before the loop
% started.  Now fixed.

function [iv,fv] = do_integral(fdat,spect,pf,iw,sfo,phases)

fdat = fdat+sfo;

% optional arguments
if(nargin<6)
  phases = [0 0];
end	

% fprintf(1,'[do_integral] phases = [%f %f]',phases);

% iv = integral value, fv = center frequency of each integral region

%pf = pf'; pf = pf(:);		% turn pf into a row vector
fv = zeros(1,length(pf));	% default zero vector for peak frequencies
iv = zeros(1,length(pf));	% default zero vector for integration results

% compute phase correction
pv = exp(i*(phases(1) + phases(2)*(fdat-pf(1)))*pi/180);
spect = spect .* pv;

for k = 1:length(pf)	% loop over peaks
	
  fpeak = pf(k);	
  fpeakrel = fpeak;% - sfo;

  % find integer indices of region to integrate over
  region = find((fdat>=(fpeakrel-iw)) & (fdat<=(fpeakrel+iw))); 

  if isempty(region)
    iv(k) = 0;		% peak frequencirs outside of fdat
  else
    iv(k) = trapz(fdat(region),spect(region)) ...
	     / trapz(fdat(region),ones(size(region)));
  end
end    


return;
  
