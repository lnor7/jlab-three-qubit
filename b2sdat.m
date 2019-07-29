% 
% File:   b2sdat.m
% Date:   23-May-97
% Author: I. Chuang <ike@lanl.gov>
% 
% MATLAB5 FUCNTION: Convert a Bruker data file set to a matlab sdat.mat file
% See NEW.DESIGN for the parameter specification.  NOTE: this version
% uses NMRX to talk with the spectrometer in real time!
% 
% usage: b2sdat(phase,apod,nresamp)
% 
% where:
% 
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
% apod		- apodization factor (0.20 = default)
%		  controls how much filtering to use when requested.  0=none.
% nresamp	- oversampling factor; controls size of the fft
%		  1 = fft buffer same as original = TD (default)
%		  n = fft buffer n * original 

function sd = b2sdat(phase,apod,nresamp)

if(nargin<3)
  nresamp = 1;
  if(nargin<2)
    if(evalin('base','isfield(calib,''apod'')'))
      apod = evalin('base','calib.apod');
    else
      apod = 0;
    end
    if(nargin<1)
      if(evalin('base','isfield(calib,''gphase'')'))
	phase = evalin('base','calib.gphase');
      else
	phase = [0 0];
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read parameters from spectrometer

tacq       = str2num(nmrx('getparm f aq'));
ns         = str2num(nmrx('getparm i NS'));
np         = str2num(nmrx('getparm i TD'));	% # of pts in the fid
sfo        = str2num(nmrx('getparm d SFO1')) * 1e6;
swh        = str2num(nmrx('getparm d SW_h'));
pp         = nmrx('getparm c pulprog');
dt         = date;
aname      = '';

% [array,nexpt] = processarray(pd,aname);
  array.name = '';
  array.val = 0;
  nexpt = 1;
dim = length(array);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read in FID

[fid,fname] = nmrx('getdat');	% the FID!!
fid = fid - mean(fid);		% nice how it works with using cplx numbers!
fid = fid.';			% put into column format
nfid = length(fid);

fname = strrep(fname,'//opt/xwinnmr/data/','');
fname = strrep(fname,'nmr/','');
fname = strrep(fname,'student/','');
fname = strrep(fname,'/','.');
s = sprintf('[fname = %s]',fname);
%disp(s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apodize and fft to get spectrum

nspect = nfid*nresamp;

apod = matchfrq(sfo,apod,'apod');	% get matching entry for struct

if(apod~=0)
  filter = exp(-(1:nspect)/nspect*apod)';
else
  filter = 1;
end

nskip = 128;
fid = [ fid(nskip+1:end); zeros(nskip,1) ];

for k = 1:nexpt
  spect(:,k) = fftshift(fft(filter.*fid(:,k),nspect));
end
fdat = linspace(-swh/2,swh/2,nspect)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% phase spectrum

for k = 1:nexpt
  spect(:,k) = dophase(spect(:,k),fdat,phase,sfo,swh);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot

clf;
d = real(spect);
dmin = min(min(d));
dmax = max(max(d));
if(dmin<0)
  theaxis = [min(fdat) max(fdat) 1.1*dmin 1.1*dmax];
else
  theaxis = [min(fdat) max(fdat) 0.9*dmin 1.1*dmax];
end
fs = sprintf('Frequency from %f in [Hz]',sfo);

for cnt = 1:nexpt
  subplot(nexpt,1,cnt);
  plot(fdat,d(:,cnt));
  grid on;
  axis(theaxis);

  xlabel(fs);
  ylabel 'Signal';

  s = sprintf('[%s] Expt %d, File: %s',date,cnt,[pwd '/' fname]);
  title(s);

  fontsize = 8;
  s = sprintf('ns=%d, pulprog=%s, sw=%6.2f %s=%6.3f',ns,pp,swh,...
      array.name,array.val(cnt));
  ylabel2(s,fontsize,1.04+0.015*rem(cnt-1,4));
end

zoom on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create data structure

sver = 2;

clear sd
sd.sver    = sver;	% structure version
sd.fid     = fid;	% fid complex data
sd.nfid    = nfid;	% number of points in fid
sd.tacq    = tacq;	% acquisition time (time length of the FID)
sd.nskip   = nskip;	% number of points to skip for initial dead time
sd.ns      = ns;	% number of scans performed in acquiring the fid
sd.spect   = spect;	% FFT'ed fid frequency spectrum
sd.nspect  = nspect;	% number of points in the spectrum
sd.fdat    = fdat;	% frequency axis data
sd.sfo     = sfo;	% spectrometer RF carrier frequency, Hz
sd.swh     = swh;	% spectral bandwidth in hertz
sd.phase   = phase;	% [zeroth, first] order phase correction
sd.apod    = apod;	% amount of exponential apodization
sd.pp      = pp;		% pulse program name
sd.fname   = fname;	% file format version number
sd.dt      = dt;		% date-time stamp for the experiment
sd.array   = array;	% list of structures giving array'ed parameters
sd.dim     = dim;	% dimension of data (i.e., 0, 1, 2,...)
sd.nexpt   = nexpt;	% number of experiments = size(fid,1), from dim>1
sd.nresamp = nresamp;	% number of times the FID was resampled for the FFT
sd.peaks   = [];
sd.int     = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save data structure to same file but with '.mat' extension

ndot = max(findstr(fname,'.'));
if(isempty(ndot))
  ndot = length(fname);
else
  ndot = ndot-1;
end
outfname = [ fname(1:ndot) '.mat' ];
save(outfname,'sd');

assignin('base','sd',sd);	% update sd structure in base environment

return

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

return;

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

  s = sprintf('oops! no valid phase found in list!');
  phase
  sfo
  disp(s);

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
