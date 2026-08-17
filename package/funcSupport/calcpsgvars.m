function t = calcpsgvars(hyp)

idx_sleep_period = find(ismember(hyp, {'n1', 'n2', 'n3', 'rem'}), 1, 'first'):find(ismember(hyp, {'n1', 'n2', 'n3', 'rem'}), 1, 'last');

t = table();
t.tib = length(hyp) * 0.5;
t.tst = sum(ismember(hyp, {'n1', 'n2', 'n3', 'rem'})) * 0.5;
t.sol = find(ismember(hyp, {'n1', 'n2', 'n3', 'rem'}), 1, 'first') * 0.5 - 0.5;
t.snooze = (length(hyp) - find(ismember(hyp, {'n1', 'n2', 'n3', 'rem'}), 1, 'last')) * 0.5;
t.remlat = find(strcmpi(hyp, 'rem'), 1, 'first') * 0.5 - t.sol - 0.5;
t.waso = sum(strcmpi(hyp(idx_sleep_period), 'wake')) * 0.5;
t.se = 100 * t.tst / t.tib;
t.n1_min = sum(strcmpi(hyp(idx_sleep_period), 'n1')) * 0.5;
t.n2_min = sum(strcmpi(hyp(idx_sleep_period), 'n2')) * 0.5;
t.n3_min = sum(strcmpi(hyp(idx_sleep_period), 'n3')) * 0.5;
t.rem_min = sum(strcmpi(hyp(idx_sleep_period), 'rem')) * 0.5;
t.n1_pct = 100* t.n1_min ./ t.tst;
t.n2_pct = 100* t.n2_min ./ t.tst;
t.n3_pct = 100* t.n3_min ./ t.tst;
t.rem_pct = 100* t.rem_min ./ t.tst;

end