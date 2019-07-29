%
% File:   NMRLoadParam.m
% Date:   21-Sep-04
%         Updated 23-Dec-05 by S. Sewell
%         Updated 05-Jan-07 by S. Sewell
%         Updated 08-Feb-10 by S.P.Robinson
%         Updated 14-Feb-10 by S.P.Robinson
%         Updated 25-Apr-19 by E. Graham
% Author: I. Chuang <ichuang@mit.edu>
% 
%
% Load the Bruker NMR parameters for the junior lab 3-qubit QIP experiments
% We put this here, in a single place, so that it is easy to change.
%
% Used by NMRCalib and NMRRunPulseProg
% 
% Usage:   NMRLoadParam('H') or NMRLoadParam('C1') or NMRLoadParam('C2')

function NMRLoadParam(nuc)
  
if(nuc=='H')
  nmrx('rpar lnorTCE-1H-shaped all');
  return
end  

if(nuc=='C1')
  nmrx('rpar lnorTCE-13C-shaped1 all');
  return
end

if(nuc=='C2')
  nmrx('rpar lnorTCE-13C-shaped2 all');
  return
end

fprintf(1,'[NMRLoadParam] ERROR! Unknown nuc=%s\n',nuc);
