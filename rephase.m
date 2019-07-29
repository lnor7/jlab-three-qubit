% 
% File:   rephase.m
% Date:   19-Jan-05
% Author: I. Chuang <ichuang@mit.edu>
% 
% Function to rephase carbon and proton data, taken with NMRCalib,
% for use in the MIT Junior Lab QIP experiment.
% 
% Usage: rephase(spectra)
% Where:
% 
% spectra	- data with carbon and proton spectra from NMRCalib
%
% To use this program:
%
% 1. Run nmrcalib, saving data to a variable, eg "myspect = NMRCalib(5)"
% 2. Run "rephase(myspect)"
% 3. Click on the proton or carbon plot window, and use the keystrokes
%    documented below to change phases.  Be sure to have peak frequencies
%    set correctly in calib before running rephase.  
% 4. Hit "q" to quit rephasing when done; the program updates values in
%    calib.gphase to the ones you last had.

function rephase(spectra)

global running_rephase thespectra thephases EP

if(nargin==1)
  thespectra = spectra;
  running_rephase = [];
  thephases = [0 0 0 0];
end

if isempty(running_rephase)	% run this the first time
  clf;
  figure(1);
  set(gcf,'keypressfcn','rephase','interruptible', 'on');
  set(gcf,'UserData',1);	% so we know which plot it is
  figure(2);
  set(gcf,'keypressfcn','rephase','interruptible', 'on');
  set(gcf,'UserData',2);
  running_rephase = 1;
  NMRplotSpectra(thespectra,1,0,thephases);
  EP = 45;

  % print out instructions
  disp('Instructions for running rephase.m');
  disp('When running the first time, do "rephase(spect)", where');
  disp('for example, spect =  NMRCalib(5,[0 0])');
  disp('');
  disp('Select the proton or carbon spectra, and use the following keys to change phase:');
  disp('< or >      - change global phase by +10 or -10');
  disp(', or .      - change global phase by +ep or -ep');
  disp('L or :      - change linear phase by +10 or -10');
  disp('l or ;      - change linear phase by +ep or -ep');
  disp('[ or ]      - decrease/increae ep by *2');
  disp('spacebar    - print out current phase change amount');
  disp('q           - quit, printing out new phase');
  disp('');
  disp('ep = epsilon');

  return
end

% retrieve the current phase
whichfig = get(gcf,'UserData');
if whichfig==1
  myphase = thephases(1:2);	% proton phases
else
  myphase = thephases(3:4);	% carbon phases
end  

dpc0 = 0;	% difference in phase correction for p0
dpc1 = 0;	% difference in phase correction for p1

c = get(gcf,'currentcharacter');
% s = sprintf('key [%d] %d (%d) %s',length(c),isstr(c),abs(c),c);
% disp(s);

if(isempty(c)) return; end

if(c=='.') 
  dpc0 = EP;
elseif(c==',') 
  dpc0 = -EP;
elseif(c=='>') 
  dpc0 = 10;
elseif(c=='<') 
  dpc0 = -10;
elseif(c=='n') 
  dpc0 = 90;
elseif(c==';') 
  dpc1 =  EP;
elseif(c=='l') 
  dpc1 = -EP;
elseif(c==':') 
  dpc1 =  10;
elseif(c=='L') 
  dpc1 = -10;
elseif(c=='[') 
  EP = EP / 2;
elseif(c==']') 
  EP = EP * 2;
elseif(c=='?') 
  disp(',/. decrease/increase PH0 by ep');
  disp('</> decrease/increase PH0 by 10');
  disp('l/; decrease/increase PH1 by ep');
  disp('L/: decrease/increase PH1 by 10');
  disp('[/] decrease/increase EP  by *2'); 
  disp('n   increase PC0 by 90');
  disp('?   show this help message');
  disp('q   quit rephasing and store result in current sd');
  disp('<spacebar> show current phasing parameters');
  fprintf(1,'EP=%8.3f\n',EP);
elseif(c==' ') 
  s = sprintf('PC0=%8.3f, PC1=%8.3f, EP=%6.3f',myphase(1),myphase(2),EP);
  disp(s);

elseif(c=='q') 			% quit
  running_rephase = [];
  exptnum = [];
  set(gcf,'keypressfcn','','interruptible', 'on');
  fprintf(1,'[rephase] Done!\n');
  gphase = evalin('base','calib.gphase');
  newgphase = gphase;
  newgphase(1,2:3) = gphase(1,2:3) + thephases(1:2);	% new proton phases
  newgphase(2,2:3) = gphase(2,2:3) + thephases(3:4);	% new carbon phases
%  newgphase(1,2:3) = thephases(1:2);	% new proton phases
%  newgphase(2,2:3) = thephases(3:4);	% new carbon phases
  fprintf(1,'          Carbon phases ph=[%8.3f %8.3f] -> [%8.3f %8.3f]\n',...
	     gphase(2,2:3),newgphase(2,2:3));
  fprintf(1,'          Proton phases ph=[%8.3f %8.3f] -> [%8.3f %8.3f]\n',...
	     gphase(1,2:3),newgphase(1,2:3));
  cmd = sprintf('calib.gphase = [%f %f %f;%f %f %f];',newgphase');
  evalin('base',cmd);
end

if((dpc0~=0)|(dpc1~=0))	% did we change the phase?
  myphase = myphase + [dpc0 dpc1];	% yes, update it
  
  pf = evalin('base','calib.pf');
  iw = evalin('base','calib.iwidth');

  if(whichfig==1)
    thephases(1:2) = myphase;
    iv = do_integral(thespectra.hfreq,thespectra.hspect,pf,iw,...
		     thespectra.hsfo,myphase);
    thespectra.hpeaks = iv(1:2);
    NMRplotSpectra(thespectra,1,0,thephases);
    figure(1);
  else
    thephases(3:4) = myphase;
    iv = do_integral(thespectra.cfreq,thespectra.cspect,pf,iw,...
		     thespectra.csfo,myphase);
    thespectra.cpeaks = iv(3:4);
    NMRplotSpectra(thespectra,1,0,thephases);
    figure(2);
  end

%  set(gcf,'keypressfcn','rephase','interruptible', 'on');
end
return
