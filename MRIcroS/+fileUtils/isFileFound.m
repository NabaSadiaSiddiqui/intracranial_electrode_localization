function [filename, isFound] = isFileFound(filename)
if exist(filename, 'file')
	isFound = true;
	return;
end
tempname = fullfile([fileparts(which('MRIcroS')) filesep '+examples'], filename);
isFound = exist(tempname, 'file');
if isFound
	filename = tempname;
end
%end isFileFound()