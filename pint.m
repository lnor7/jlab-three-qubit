% 
% File:   pint.m
% Date:   24-May-97
% Author: I. Chuang <ike@isl.stanford.edu>
% 
% MATLAB5 Function: do peak integrals of sdat format file
% We use the global variables "calib.pf" and "calib.iwidth", and "sd"
% 
% Be sure to load calib.mat before running this!
% 
% pf.frq = frequency of peaks to integrate
% calib.iwidth = half-width (to left and right) of region to integrate
% 
% usage: iv = pint()
% where:
% 
% iv		- region integral values

function iv = pint()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do each specturm separately

sn = evalin('base','sd');
pf = evalin('base','calib.pf');
iw = evalin('base','calib.iwidth');

for k = 1:(sn.nexpt)
  [iv(k,:),fv] = do_integral(sn.fdat,sn.spect(:,k),pf,iw,sn.sfo);
  fprintf(1,'[%d] iv = ',k);
  for j = 1:length(iv(k,:))
    fprintf(1,'%10.3f  ',iv(k,j));
  end
  fprintf(1,'\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save data back to main structure

assignin('base','iv',iv);
assignin('base','fv',fv);
evalin('base','sd.int.pf = calib.pf;');
evalin('base','sd.int.intwidth = calib.iwidth;');
evalin('base','sd.int.iv = iv;');
evalin('base','sd.int.fv = fv;');

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION helper: integrate peaks in spectrum

function [iv,fv] = do_integral(fdat,spect,pf,iw,sfo)

% iv = integral value, fv = center frequency of each integral region

cnt = 0;
for k = 1:length(pf)
  frq = pf(k).frq - sfo;
  for j = 1:length(frq)
    ff = frq(j);
    cnt = cnt+1;
    fv(cnt) = ff;
    region = find((fdat>=(ff-iw)) & (fdat<=(ff+iw))); % index of int region
    if isempty(region) iv(cnt) = 0;  % only do if frq is in spectral range
    else 
      iv(cnt) = trapz(fdat(region),spect(region)) ...
	        /trapz(fdat(region),ones(size(region)));
    end
  end
end
