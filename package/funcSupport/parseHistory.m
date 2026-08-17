function History = parseHistory(FullFilePath)

Code = readcell(FullFilePath);

History = struct();
cnt = 0;
for l = 1:size(Code, 1)
    Ln = Code{l};
    if length(Ln) < 5
        continue
    end
    if strcmpi(Ln(1:5), '%%% C')
        cnt = cnt+1;
        Section = strsplit(Ln, '''');
        History(cnt).Process = Section{2};
        History(cnt).DateTime = strtrim(strrep(strrep(Section{3}, '(', ''), ')', ''));
        History(cnt).Settings = struct();
    end
    if strcmpi(Ln(1:5), 'Setti')
        eval(['History(cnt).', Ln]); %#ok<EVLDOT>
    end
end

end