% 
% File: NMRCalib.m
% Date: 21-Jan-03
% Author: Kenneth Jensen <sanctity@mit.edu>
%
% Description:  Performs a pulse of pulse width pw on each spin,
% separately, and records the spectra.  First, this should be used
% to find the correct phase offset.  Next, it may be used to find
% the 90 degree pulse widths on the hydrogen and carbon spins.
%
% Usage:  spect = NMRCalib( pw, phref, d1 )
%
% Where:
%
% pw    - pulse width in microseconds
% phref - 1x2 vector of offset phases for the the hydrogen and
%         carbon signal
% d1    - delay before pulses (optional!  default = 50 seconds)
%
% spect - a structure for holding all the data from the experiment
%   spect.tacq               - acquistion time for both hydrogen
%                              and carbon
%   spect.hfreq              - hydrogen frequency data
%   spect.hsfo               - hydrogen transmitter frequency
%   spect.hspect             - hydrogen spectrum
%   spect.hfid               - hydrogen free induction decay 
%   spect.hpeaks             - hydrogen peak integral values
%   spect.hphase             - hydrogen offset phase
%   spect.cfreq              - carbon frequency data 
%   spect.csfo               - carbon transmitter frequency
%   spect.cspect             - carbon spectrum
%   spect.cfid               - carbon free inducation decay
%   spect.cpeaks             - carbon peak integral values
%   spect.cphase             - carbon offset phase
%   spect.pp                 - pulse program structure (note: in
%                              this case there isn't really a pulse '
%                              program.  this structure 
%                              is just used to hold the pulse
%                              width) 
%   spect.pp.pw90            - 90 degree pulse widths used
%   spect.dt                 - date and time
%
% Example: spect = NMRCalib( 5, [0 0] );
%
% This performs a 5us pulse on the hydrogen and measures the
% hydrogen spectrum.  Then it performs a 5us pulse on the carbon
% and measures the carbon spectrum. 
%
% Modified 10-Feb-17 by SPR. Commented out playfid and added countdowndelay
% Modified 13-aug-18 by SPR. Fixed up the error checking on arguments


function spect = NMRCalib( pw, phref, d1 )

    countdowndelay = 9; % extra time that the coutdown needs to get going.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% basic error checking

if ~(nargin==1 | nargin==2 | nargin==3 )
  error('This function takes 1 or 2 or 3 inputs');
end;

if length(pw) ~= 1
  error('pw should just be one number');
end;

if nargin >1
if length(phref) ~= 2
  error('phref must have the form [hydrogen_pc0, carbon_pc0]');
end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%% process inputs

if nargin < 3
  d1 = 50;
  if nargin < 2
    gphase = evalin('base','calib.gphase');
    phref = gphase(:,2)'; %' if no global phase is provided, 
                          % read in from calib.gphase 
  end;
end;

NMRSetCalibPhases(phref(1),phref(2));  % store phase references data in calib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% perform pulse on hydrogen

% load parameter file for hydrogen
NMRLoadParam('H');
     
% set the delay between pulses
if ( nargin==3 )
  nmrx( strcat(['d1 ', num2str( d1 )]) );
end;

% set 90 degree pulse width for hydrogen
nmrx( strcat(['p1 ', num2str( pw )]) );
      
% set pulse program
nmrx( 'pulprog zg' );  

fprintf( 1, 'Performing %fus pulse on hydrogen...\n', pw );

% run countdown program
system( sprintf('/home/nmrqc/matlab/delay %d &', d1+countdowndelay) );

% run pulse program
nmrx( 'zg' );      
     
% get data and fourier transform
mysdh = b2sdatNoPlot; % Note, this reads in and applies global and
                      % linear phase correction from calib.gphase

% play the fid through the speakers
playfid( mysdh.fid );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% perform pulse on carbon

% load parameter file for carbon
NMRLoadParam('C');

% set the delay between pulses
if ( nargin==3 )
  nmrx( strcat(['d1 ', num2str( d1 )]) );
end;

% set pulse program
nmrx( 'pulprog zg' );  

% set 90 degree pulse width for carbon
nmrx( strcat(['p1 ', num2str( pw )]) );

fprintf( 1, 'Performing %fus pulse on carbon...\n', pw );

% run countdown program
system( sprintf('/home/nmrqc/matlab/delay %d &', d1+countdowndelay) );

% run pulse program
nmrx( 'zg' );      
     
% get data and fourier transform
mysdc = b2sdatNoPlot; % Note, this reads in and applies global and
                      % linear phase correction from calib.gphase

% play the fid through the speakers
playfid( mysdc.fid );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% process output

pf = evalin('base','calib.pf');
iw = evalin('base','calib.iwidth');


spect.hfreq = mysdh.fdat;
spect.hsfo = mysdh.sfo;
spect.hspect = mysdh.spect;
spect.hfid = mysdh.fid;
spect.hphase = phref(1);

iv = do_integral( mysdh.fdat, mysdh.spect, pf, iw, mysdh.sfo );
spect.hpeaks = iv(1:2);			   

spect.cfreq = mysdc.fdat;
spect.csfo = mysdc.sfo;
spect.cspect = mysdc.spect;
spect.cfid = mysdc.fid;
spect.cphase = phref(2);

iv = do_integral( mysdc.fdat, mysdc.spect, pf, iw, mysdc.sfo );
spect.cpeaks = iv(3:4);

spect.pp.pw90 = [pw pw];

spect.dt = dt;

spect.tacq = [ mysdh.tacq mysdc.tacq ]; % 29-Apr-03 ILC   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% save data

s = sprintf('save spect-%s spect;', spect.dt); eval(s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% save both mysdc and mysdh as global variables  (added 06-Jan-06 ILC)

assignin('base','mysdc',mysdc);
assignin('base','mysdh',mysdh);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot spectra

NMRplotSpectra( spect ); % do not supply optional phase corrections here, 
                         % because they are already applied to the data
                         % returned from b2sdatNoPlot.
% $$$ figure(1)
% $$$ plot(spect.hfreq,real(spect.hspect));
% $$$ axp=axis;
% $$$ axp(4)=axp(4)*1.1;
% $$$ axp(3)=-axp(4);
% $$$ save axp axp;
% $$$ grid on;
% $$$ s=sprintf('proton spectrum - [%s]',spect.dt);
% $$$ title(s);
% $$$ ylabel('signal [arb. units]');
% $$$ xlabel('frequency from hsfo');
% $$$ 
% $$$ figure(2)
% $$$ plot(spect.cfreq,real(spect.cspect));
% $$$ axc=axis;
% $$$ axc(4)=axc(4)*1.1;
% $$$ axc(3)=-axc(4);
% $$$ save axc axc;
% $$$ grid on;
% $$$ s=sprintf('carbon spectrum - [%s]',spect.dt);
% $$$ title(s);
% $$$ ylabel('signal [arb. units]');
% $$$ xlabel('frequency from csfo');

return;
