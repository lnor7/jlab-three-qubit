%
% File: NMRStartup.m
% Date: 21-Jan-03
% Author: Kenneth Jensen
%
% Description:  Startup script for the QIP junior lab experiment.
% Adds paths and loads calib into the base workspace.  This should
% be run at the start of any QIP matlab session.


addpath /home/nmrqc/matlab

% saves the current shim file
[s currentUser] = system('whoami');
currentUser = currentUser(1:length(currentUser)-1);

% s = sprintf('wsh NMRshim-%s-%s', currentUser, dt );
% nmrx( s );

% These lines were commented out by SDS on 28Jan05.  It was causing
% a overwrite message on the bruker machine which could be confusing to
% students, who are not expected to work on that machine.
% It also does not appear to be necessary to write the shim files over to each 
% students directory.



load calib;
