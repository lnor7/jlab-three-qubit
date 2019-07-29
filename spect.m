% 
% File:   spect.m
% Date:   15-May-97
% Author: I. Chuang <ike@lanl.gov>
% 
% MATLAB5 FUCNTION: Plot spectrum of a sdat format struct file.
%
% 13-Feb-99 ILC: changed to stacked spectrum, and if global variable
%                num is set, then it only does apod & reprocessing of
%                that spectrum (or set of spectra).
% 
% usage: dy = spect(sname,phase,range,apod,nresamp)
% 
% where:
% 
% dy            - delta in y-axis location between spectra in stacked spectra
% sname		- the spectrum data structure
%                 if it is a two-component cell {sd,cntlist} 
%                 then cntlist is taken as an array of spectra to plot
% phase  	- phase of real and imaginary fft to use
%	    	  0-360 = normal phase angle (default=0)
%		  1000  = absolute magnitude
%		  1200  = log10(abs(dat))
%		  1400  = complex phase (in degrees)
%		  2000  = use complex value; do not plot
%		  3000  = plot FID (and return d = time domain data)
%		  may also be a vector [freqp pc0 pc1 ; freqx xc0 xc1 ; ...] in
%		     which case the program chooses the first row that
%		     fits in the frequency range of the current spectrum
%		     and uses it for zeroth and first order phase correction.
% range		- frequency range [f1, f2] to plot
%		  []      = full range	(default)
%		  [width] = range from middle -/+ width
%		  [f1,f2] = range from f1 to f2 (give in KHz)
% apod		- apodization factor (0.20 = default)
%		  controls how much filtering to use when requested.  0=none.
% nresamp	- oversampling factor; controls size of the fft
%		  1 = fft buffer same as original = TD (default)
%		  n = fft buffer n * original 
% 
% For multidimensional datasets, if the global variable "num" exists
% then its value will be used as the list of the dataset numbers to plot.

function dy = spect(sn,phase,range,apod,nresamp)

global sd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% select which spectra to process

if(nargin<1)
  sn = evalin('base','sd');
end

if(iscell(sn))
  cntlist = sn{2};
  sn = sn{1};
else
  if(evalin('base','exist(''num'')')==1)
    cntlist = evalin('base','num');
    if isempty(cntlist) cntlist = 1:sn.nexpt; end
  else
    cntlist = 1:sn.nexpt;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process input arguments

if(nargin<5)
  nresamp = 1;
  if(nargin<4)
    if(nargin<3)
      range = [];
      if(nargin<2)
	phase = [];
      end
    end
    apod = matchfrq(sn.sfo,sn.apod,'apod'); % get matching entry for struct
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apodize spectrum & resample 

filter = exp(-(1:sn.nspect)/sn.nspect*apod)';

nspect = sn.nfid * nresamp;
for k = cntlist
%  d(:,k) = sn.spect(:,k);
  d(:,k) = fftshift(fft(filter.*sn.fid(:,k),nspect));
end
fdat = linspace(-sn.swh/2,sn.swh/2,nspect)';	% frequency axis

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chop out requested range

if(~isempty(range))
  if(length(range)==1)
    range = [-range range] + sn.sfo;
  end
  rbounds = round((range - sn.sfo) * ...
      		sn.nspect/sn.swh) + sn.nspect/2; % indices
  regidx = rbounds(1):rbounds(2);
  d = d(regidx,:);
  fdat = fdat(regidx);
else
  regidx = [1 length(d)];
  rbounds = [ 1 length(d) ];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% phase spectrum

if(isempty(phase)) phase = sn.phase; end;

for k = cntlist
  d(:,k) = dophase(d(:,k),fdat,phase,sn.sfo,sn.swh);
end

assignin('base','sdat',d);	% store spect data back in base environment

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot

clf;

d = real(d);
dmin = min(min(d(:,cntlist)));
dmax = max(max(d(:,cntlist)));
if(dmin<0)
  theaxis = [min(fdat) max(fdat) 1.1*dmin 1.1*dmax];
else
  theaxis = [min(fdat) max(fdat) 0.9*dmin 1.1*dmax];
end
fs = sprintf('Frequency from %10.2f in [Hz]',sn.sfo);

doold = 0;
if(doold)

  nplot = 1;
  for cnt = cntlist
    subplot(length(cntlist),1,nplot);
    plot(fdat,d(:,cnt));
    grid on;
    axis(theaxis);
    nplot = nplot + 1;
    
    xlabel(fs);
    ylabel 'Signal';
    
    s = sprintf('[%s] Expt %d, File: %s',date,cnt,[pwd '/' sn.fname]);
    title(s);
    
    fontsize = 8;
    if(length(sn.array)==1)
      s = sprintf('ns=%d, pulprog=%s, sw=%6.2f %s=%6.3f',sn.ns,sn.pp,sn.swh,...
	  sn.array.name,sn.array.val(cnt));
    else
      s = sprintf('ns=%d, pulprog=%s, sw=%6.2f',sn.ns,sn.pp,sn.swh);
    end
    ylabel2(s,fontsize,1.04+0.015*rem(cnt-1,4));
    
    % plot peaks if present
    
    if ~isempty(sn.peaks)
      hold on;
      pk = sn.peaks(cnt);
      v = d(pk.loc,cnt);
      plot(pk.relfrq,v,'go');
      for k = 1:length(pk.loc)
	p = pk.relfrq(k);
	dd = v(k);
	s = sprintf('%8.4f',p+sn.sfo);
	q = text('posi',[p,1.08*dd],'vis','on','string',s,...
	    'color','k','horiz','center','vertical','middle','FontSize',8);
      end
    end
    
    % label peak integrals if they exist
    
    if ~isempty(sn.int)
      hold on;
      fv = sn.int.fv(:);
      iv = sn.int.iv(cnt,:)/1000;
      iw = sn.int.intwidth;
      for j = 1:length(fv)
	ff = fv(j);
	region = find((fdat>=(ff-iw)) & (fdat<=(ff+iw)));
	if ~isempty(region)
	  y1 = max(real(d(region,cnt)));
	  y2 = min(real(d(region,cnt)));
	  if(abs(y2)>abs(y1)) ypos = y2; else ypos = y1; end
	  
	  [dummy,idx] = min(abs(fdat-ff));
	  y0 = d(idx(1),cnt);
	  plot(ff,y0,'go');
	  
	  s = sprintf('%8.2f + %8.2fi',real(iv(j)),imag(iv(j)));
	  text('posi',[ff,ypos],'vis','on','string',s,...
	      'color','k','horiz','center','vertical','middle','FontSize',18);
	end
      end
    end
  end
else	% doold

  % plot stacked spectrum in y direction, all in one plot
  % compute y-axis separation between spectra lines

  for k = 1:length(cntlist)
    dytab(k) = max(d(:,cntlist(k))) - min(d(:,cntlist(k)));
  end
  dyavg = mean(dytab);
  dy = 0.75 * dyavg;

  % compute axes

  theaxis = [min(fdat) max(fdat) 1.1*dmin 1.1*dmax+(length(cntlist)-1)*dy];

  % make stacked plots

  delta = 0;
  nplot = 1;
  for cnt = cntlist
    plot(fdat,d(:,cnt)+delta);
    if(nplot==1)
      hold on;
      grid on;
      axis(theaxis);
      xlabel(fs);
      ylabel 'Signal';
    
      if(length(cntlist)==1)
	s = sprintf('[%s] Expt %d, File: %s',date,cnt,[pwd '/' sn.fname]);
      else
	s = sprintf('[%s] Expt %d-%d File: %s',date,...
	    min(cntlist),max(cntlist),...
	    [pwd '/' sn.fname]);
      end
      title(s);
      
      fontsize = 8;
      if(length(sn.array)==1)
	s = sprintf('ns=%d, pulprog=%s, sw=%6.2f %s=%6.3f',...
	    sn.ns,sn.pp,sn.swh,...
	    sn.array.name,sn.array.val(cnt));
      else
	s = sprintf('ns=%d, pulprog=%s, sw=%6.2f',sn.ns,sn.pp,sn.swh);
      end
      ylabel2(s,fontsize,1.04+0.015*rem(cnt-1,4));
    end
    nplot = nplot + 1;
    
    % plot peaks if present
    
    if ((~isempty(sn.peaks)) & (length(sn.peaks)==sn.nspect))
      hold on;
      pk = sn.peaks(cnt);
      v = d(pk.loc,cnt)+delta;
      plot(pk.relfrq,v,'go');
      for k = 1:length(pk.loc)
	p = pk.relfrq(k);
	dd = v(k)+delta;
	s = sprintf('%8.4f',p+sn.sfo);
	q = text('posi',[p,1.08*dd],'vis','on','string',s,...
	    'color','k','horiz','center','vertical','middle','FontSize',8);
      end
    end
    
    % label peak integrals if they exist
    
    if ~isempty(sn.int)
      hold on;
      fv = sn.int.fv(:);
      iv = sn.int.iv(cnt,:)/1000;
      iw = sn.int.intwidth;
      for j = 1:length(fv)
	ff = fv(j);
	region = find((fdat>=(ff-iw)) & (fdat<=(ff+iw)));
	if ~isempty(region)
	  y1 = max(real(d(region,cnt)));
	  y2 = min(real(d(region,cnt)));
	  if(abs(y2)>abs(y1)) ypos = y2; else ypos = y1; end
	  
	  [dummy,idx] = min(abs(fdat-ff));
	  y0 = d(idx(1),cnt)+delta;
	  plot(ff,y0,'go');
	  
	  s = sprintf('%8.2f + %8.2fi',real(iv(j)),imag(iv(j)));
	  text('posi',[ff,ypos+delta],'vis','on','string',s,...
	      'color','k','horiz','center','vertical','middle','FontSize',18);
	end
      end
    end
    delta = delta + dy;
  end

end

zoom on;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot helper function

function ylabel2(str,size,xpos)

if(nargin<3)
  xpos = 1.05;
  if(nargin<2)
    size = 8;
  end;
end

q = text('posi',[0,0],'vis','off','units','norm','string',str,...
    'color','k','rotation',90,'horiz','center','FontSize',size,...
    'position',[xpos,0.5],'vertical','middle','horiz','center','vis','on');

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% phase spectrum helper function

function y = dophase(x,fdat,phase,sfo,swh)

if(isstruct(phase))	% general linear phase correction from a set

  for k = 1:length(phase)	% go through rows until one is valid
    pent = phase(k);
    if(abs(pent.frq-sfo)<2*swh) 
      pv = (pent.phase(1) + fdat * pent.phase(2)/swh)*pi/180;
      y = x .* exp(i * pv);
      return;
    end
  end

  s = sprintf('oops! no valid phase found in list! sfo=%12.2f',sfo);
%  phase
%  sfo
  disp(s);
  y = x;

elseif(length(phase)==2)	% do general linear phase correction

  pv = (phase(1) + fdat * phase(2)/swh)*pi/180;
  y = x .* exp(i * pv);

elseif(size(phase,2)==3)	% general linear phase correction from a set

  for k = 1:size(phase,1)	% go through rows until one is valid
    pent = phase(k,:);
    if(abs(pent(1)-sfo)<2*swh) 
      pv = (pent(2) + fdat * pent(3)/swh)*pi/180;
      y = x .* exp(i * pv);
      return;
    end
  end

  s = sprintf('oops! no valid phase found in list = %6.4f',phase);
  disp(s);

elseif(phase <= 360)

  y = exp(i*phase * pi/180) * x;

elseif(phase==1400)

  y = unwrap(angle(x)) * 180/pi;

elseif(phase==1000)

  y = abs(x);

elseif(phase == 1200)

  y = log10(abs(x));

end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper function: get structure entry corresponding to frequency

function x = matchfrq(frq,sdat,param)

if ~isstruct(sdat) x = sdat; return; end	% return if not structure

for s = sdat	% search for match
  if (s.frq==frq)
    x = getfield(s,param);
    return; 
  end
end

x = 0;
return;

