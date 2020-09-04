clear all;
close all;
load hospital
x = hospital.Weight;
pd = fitdist(x,'Normal');
x_values = 50:1:250;
y = pdf(pd,x_values);
plot(x_values,y,'LineWidth',2);
ci = paramci(pd);
mean(x)
std(x)