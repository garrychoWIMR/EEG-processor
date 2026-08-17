function b = mergestruct(a, b)

f = fieldnames(a);
for i = 1:length(f)
    b.(f{i}) = a.(f{i});
end

end