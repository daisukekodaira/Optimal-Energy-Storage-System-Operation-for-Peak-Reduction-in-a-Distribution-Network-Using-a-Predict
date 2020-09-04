load hospital
y = datasample(hospital,size(hospital,1));
x1 = randn(100,1);
x2 = randn(100,1);
[y1,idx] = datasample(x1,10);
y2 = x2(idx);