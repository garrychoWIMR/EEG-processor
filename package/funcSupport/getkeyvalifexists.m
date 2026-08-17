function val = getkeyvalifexists(S, f)
val = '';
if isfield(S, f)
    val = S.(f);
end
end