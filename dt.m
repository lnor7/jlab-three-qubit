%
% File:   dt.m
% Date:   21-Sep-04
% Author: I. Chuang <ichuang@Mit.edu>
%
% Matlab function under unix which gets the current date & time in a nice
% format string

function dt = dt()

[s,x] = unix('date +"%d%b%y-%H%M%S"');
if ~isempty(findstr(x(1:end-2),10))
  k = findstr(x(1:end-2),10);
  x = x(k(end)+1:end);
end

dt = x(1:end-1);
