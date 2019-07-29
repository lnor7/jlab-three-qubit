%
% File:   NMRSetCalibPhases.m
% Date:   10-Feb-06
% Author: I. Chuang <ichuang@mit.edu>
%
% Main matlab routine to store phases in the global "calib" data
% structure; this is called by NMRRunPulseProg and NMRCalib
% after the spectra are taken.
%
% The calib data structure has a field calib.gphase which stores
% the phase reference data for the proton and carbon channels, in the
% format [h-freq-Mhz hph0 hph1; c-freq-Mhz cph0 cph1];
% BF1 = 200.13 MHz, BF2 = 50.32 MHz are the frequencies from  XWinNMR, 
% which may have to be changed every time the magnet is recharged 
%
% Modified 11-Mar-2014 by SPR. changed things so that the base frequencies
% are not just 200.0 and 50.0 all the time.
%
function NMRSetCalibPhases(php0,php1,phc0,phc1)

BFh = 200.13119940;
BFc =  50.32656767;

%PC1h = 168.648;	% linear phase correction factors for p & c
%PC1c = 127.066;	% hardwired here, because they don't change much!

%PC1h = 165.394;	% Trying the old ones again
%PC1c = 130.825;	

%PC1h = 190; % the units are degrees / ~250 MHz (i.e. half bandwidth)
%PC1c = 211; % Feb 2011

%PC1h = 165.394;
%PC1c = 168; % Updated RHF Jan 2012

%PC1h = -01.797638;
%PC1c =  11.182919; % Updated SPR Mar 2014

%PC1h = 166.10487;
%PC1c =  166.11327; % Updated SPR Sep 2017

PC1h = 178.000784;
PC1c = 157.430857; % Updated SPR Aug 2018. 
                   % For global, try php=142.271852 and phc= -45.229492

evalin('base', sprintf('calib.gphase = [%f %f %f ; %f %f %f ];', ...
      BFh,php0,php1,BFc,phc0,phc1));
