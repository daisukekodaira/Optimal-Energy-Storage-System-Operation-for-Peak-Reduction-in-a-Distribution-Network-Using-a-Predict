clear all;
MU1 = [1 2];
SIGMA1 = [2 0; 0 1.5];
MU2 = [-3 -5];
SIGMA2 = [2.5 0; 0 2.5];
X =20+ [mvnrnd(MU1,SIGMA1,50000);mvnrnd(MU2,SIGMA2,50000)];
histogram(X(:,1));
histogram(X(:,2));

