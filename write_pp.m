%
% File: write_pp.m
% Date: 10-Jan-03
% Author: Kenneth Jensen <sanctity@mit.edu>
%
% Description:  Makes a Bruker pulse program according to the arrays
% pulses, phases, delays.  The pulse program is saved as 
%
% Usage: write_pp( pulses, phases, delays, measure );
%
% pulses - 2xN array of pulses lengths where the first row
% represents the pulses on the hydrogen, and the second row
% represents the pulses on the carbon.  the pulse lengths are in
% terms of the 90 degree pulse length (ie. 1 = 90 degrees)
%
% phases - 2xN array of phases where the first row represents
% the phases of the hydrogen's pulses and the second row
% represents the phases of the carbon's pulses.  the phases
% are in units of 90 degrees (ie. 1 = 90 degrees )
%
% delays - 1xN array of delays in millisec.  the Nth delay follows 
% the Nth set of pulses on the two spins.
%
% measure - determines which nucleus is measured, 0 for
% hydrogen, 1 for carbon
%
% Example: write_pp( [2 1; 0 0], [0 0; 0 0], [100 0], 0 );
%
% This example performs an inversion-recovery sequence, 180-tau-90,
% on the first spin with tau = 100ms.  The fid of the hydrogen
% nucleus is measured.

function write_pp( pulses, phases, delays, measure )

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % perform basic error checking 
   if nargin ~= 4
     error('Wrong number of arguments');
   end; 

   if size(pulses,1) ~= 3
     error(['Pulses should have the form [hydrogen_pulse_1 ...' ...
	    ' hydrogen_pulse_n;  carbon_pulse_1 ... carbon_pulse_n]']); 
   end;

   if size(phases,1) ~= 3
     error(['Phases should have the form [hydrogen_phase_1 ...' ...
	    ' hydrogen_phase_n;  carbon_phase_1 ... carbon_phase_n]']); 
   end;

   if size(delays,1) ~= 1 
     error('Delays should have the form [delay_1 ... delay_n]');
   end;

   if size(delays,2)~=size(pulses,2) | size(delays,2)~=size(phases,2)
     error('Pulses, phases, and delays should all have the same length');
   end;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write bruker pulse program file
   fd = fopen( 'juniorlabpp', 'w' );
   fprintf( fd, '#include <Avance.incl>\n\n' );
   fprintf( fd, '1 ze\n' );
   fprintf( fd, '2 d1\n' );

   for count = 1:size(pulses,2)

     if measure == 0
       % hydrogen is first channel
       
       if pulses(1,count) > 0
	 fprintf( fd, 'p1*%d:f1 ph%d\n', pulses(1,count), phases(1,count));
       end;
       
       if pulses(2, count) > 0
	 fprintf( fd, 'p11*%d:sp1:f2 ph%d\n', pulses(2,count), phases(2,count));
     fprintf(fd,'3u\n');
       end;
       
       if pulses(3, count) > 0
     fprintf( fd, 'p12*%d:sp2:f2 ph%d\n', pulses(3,count), phases(3,count));
     fprintf(fd,'3u\n');
       end
       
     else
       % carbon is first channel
       
       if pulses(1,count) > 0
	 fprintf( fd, 'p1*%d:f2 ph%d\n', pulses(1,count), phases(1,count));
       end;
       
       if pulses(2, count) > 0
	 fprintf( fd, 'p11*%d:sp1:f1 ph%d\n', pulses(2,count), phases(2,count));
     fprintf(fd,'3u\n');
       end;
       
       if pulses(3, count) > 0
	 fprintf( fd, 'p12*%d:sp2:f1 ph%d\n', pulses(3,count), phases(3,count));
     fprintf(fd,'3u\n');
       end;
     end;
     
     if delays(count) > 0
     fprintf( fd, '%fm\n',delays(count));
     end
     
   end;
   
   fprintf( fd, 'go=2 ph31\n' );
   fprintf( fd, 'wr #0\n' );
   fprintf( fd, 'exit\n\n' );

   fprintf( fd, 'ph0=0 2 2 0 1 3 3 1\n' );
   fprintf( fd, 'ph1=1 3 3 1 2 0 0 2\n' );
   fprintf( fd, 'ph2=2 0 0 2 3 1 1 3\n' );
   fprintf( fd, 'ph3=3 1 1 3 0 2 2 0\n' );
   fprintf( fd, 'ph31=0 2 2 0 1 3 3 1\n' );
   
   fclose( fd );
