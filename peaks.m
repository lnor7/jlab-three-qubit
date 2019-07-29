% 
% File:   peakit.m
% Date:   20-May-97
% Author: I. Chuang <ike@lanl.gov>
% 
% MATLAB5 FUCNTION: find peaks in a sdat format FID file
%
% Instructiosn for use with junior lab setup:
%
% After running NMRCalib, you will have structures mysdc (carbon) 
% and mysdh (proton).  To find peak locations of spectra, run
% pc = peaks(mysdc) and ph = peaks(mysdh).
%
% Next, update locations of peak positions in the global calib structure
% variable by doing
%
%   calib.pf(2,:) = pc.frq(:);
%   calib.pf(1,:) = ph.frq(:);
%
% save the calibration file using "save calib calib"
%
% Usage:
% 
%  [peakloc,peakval,d] = peakit(sname,verboseflag,thresh_peak, ...
%     					thresh_dist,thresh_same,smoothfac);
% where 
% 
% peakloc	- vector of location of peaks
% peakval	- vector of heights of peaks
% d		- data vector
% 
% sname		- name of the spectrum data structure
% verboseflag	- 1=lots of output, plots
% thresh_peak	- default = 0.25, fraction over which to call a peak
% thresh_dist	- default = 200, separation between peak windows
% thresh_same	- default = 20, peaks closer than this are ignored (solitary)
% smoothfac	- default = 0.1, smoothing factor
% 

function peakfrq = findpeak(sn,verboseflag,thresh_peak, ...
    					thresh_dist,thresh_same,smoothfac);

if(nargin<6)
  smoothfac = 0.1;
  if(nargin<5)
    thresh_same = 2;
    if(nargin<4)
      thresh_dist = 100;
      if(nargin<3)
	thresh_peak = 0.2;
	if(nargin<2)
	  verboseflag = 1;
	  if(nargin<1)
	    sn = evalin('base','sd');
	  end
	end
      end
    end
  end
end

% thresh_dist = 200;
% thresh_same = 20;
% thresh_peak = 0.50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process each 1D FID at a time

if(verboseflag==1)
  spect(sn,1000);
end

clear peakfrq
if(isfield(sn,'peaks'))	% start from old peak data if it exists
  peakfrq = sn.peaks;
end


if(evalin('base','exist(''num'')')==1)
  cntlist = evalin('base','num');
  if isempty(cntlist) cntlist = 1:sn.nexpt; end
else
  cntlist = 1:sn.nexpt;
end

nplot = 1;
for k = cntlist

  d = abs(sn.spect(:,k));
  peakloc = do_peaks(d,verboseflag,thresh_peak, ...
				thresh_dist,thresh_same,smoothfac);
  
  peakf = sn.fdat(peakloc);
  peakfrq(k).frq = peakf + sn.sfo;
  peakfrq(k).relfrq = peakf;
  peakfrq(k).loc = peakloc;
  peakfrq(k).val = d(peakloc);

  if(verboseflag==1)
    subplot(length(cntlist),1,nplot);
    hold on;
    plot(peakf,d(peakloc),'go');
    nplot = nplot + 1;
    for k = 1:length(peakloc)
      p = peakf(k);
      dd = d(peakloc(k));
      s = sprintf('%10.4f [kHz] [abs=%12.3f]: %10.2f',p,p+sn.sfo,dd);
      disp(s);
      s = sprintf('%8.4f',p+sn.sfo);
      q = text('posi',[p,1.08*dd],'vis','on','string',s,...
	  'color','k','horiz','center','vertical','middle','FontSize',8);
    end
    drawnow;
  end
end 

if(verboseflag==1)
  zoom on;
  for k = cntlist
    pm = mean(peakfrq(k).relfrq);
    s = sprintf('[%d] Mean frequency of peaks: %10.3f (abs=%12.3f)]',...
      k,pm,pm+sn.sfo);
    disp(s);
  end
end

if((nargin==0)|(verboseflag==2))
  assignin('base','pk',peakfrq);
  evalin('base','sd.peaks = pk;');
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find peak function

function peakloc = do_peaks(data,verboseflag,thresh_peak, ...
			      thresh_dist,thresh_same,smoothfac)

d = abs(data);

XMIN = 1;
XMAX = length(d);
x = XMIN:XMAX;

% first find maxima 

dmax = max(d);
ds = d / max(d);			% rescale data to go between 0 and 1
xmax = sort(find(ds>thresh_peak));	% find maxima

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% group maxima together into windows

xold = xmax(1);
xfirst = xold;
wintab = [];

for k = 2:length(xmax);
  dist = xmax(k)-xold;
  if(dist>thresh_dist)
%    [xold xfirst]
    if(xold-xfirst>thresh_same)
      wintab = [wintab ; [xfirst xold]];
    else
      s = sprintf('warning: solitary peak at [%d,%d] skipped',xfirst,xold);
      disp(s);
    end
    xfirst = xmax(k);
  end
  xold = xmax(k);
end

if(xold-xfirst > thresh_same) 
  wintab = [wintab ; [xfirst xold]];
end

% wintab

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% smooth the data in each window and find peaks using zero crossing detection

peakloc = [];
peakval = [];

for k = 1:size(wintab,1)
  x1 = wintab(k,1);
  x2 = wintab(k,2);
  dist = x2-x1;
  x1 = max([x1 - floor(0.2*dist),XMIN]);
  x2 = min([x2 + floor(0.2*dist),XMAX]);
  xr = x1:x2;	% range for current window
  dsm = csaps(xr,data(xr),smoothfac,xr);	% smooth the data for easy zc
  % dsm = smooth(data(xr),10);	% smooth the data for easy zc
  dsm = dsm/max(abs(dsm));	% renormalize
  dsmi = find(abs(dsm)>0.5);	% find local peaks
  dsm2 = zeros(size(dsm));	% make buffer for windowed maxes
  dsm2(dsmi) = dsm(dsmi);	% make local windowed maxes
  % 31-Mar-97 ILC: added "-1" to next line
  peakloc0 = find(abs(diff(sign(diff(dsm2))))>1)-1;	% find zero crossings
  idx = find(peakloc0>0);
  peakloc0 = peakloc0(idx);		% remove negative & zero entries
  peakval0 = dsm(peakloc0).*dmax;	% get values (and rescale)
  peakloc = [peakloc peakloc0+x1];
  peakval = [peakval peakval0];
  
  if(verboseflag==10)	  % plot intermediate results 
    hold off;
    plot(xr,dsm);
    hold on;
    plot(peakloc0+x1,ones(size(peakloc0)),'go');
    grid on;
    s0 = sprintf('%d ',peakloc0+x1);
    s1 = sprintf('%f ',peakval0);
    s = sprintf('[%d] (%d,%d) peaks at %s, values %s',k,x1,x2,s0,s1);
    disp(s);
    pause;
  end

  if(length(peakloc)>20)
    fprintf(1,'[peaks] oops! too many peaks, stopping search...\n');
    break;
  end
end

% print -dps findpeak2.ps

return;
