function PoissonGqThbMl(nEL)
%% There are still a lot of bugs! Test!!
% [parameters, obj] = param();
% f = parameters.f;
% g = parameters.g;
a = 0;
b = 2;
p = 3;
N = nEL;
resol = 0.001;
lvl = 3;%parameter.a,parameter.b,parameter.p,parameter.N,parameter.resol,parameter.lvl
obj = thbSplBasML(a,b,p,N,resol,lvl);
f = @(x)  pi.^2/4*sin(pi/2*x);%source function 
g = @(x) sin(pi/2*x);

dBC = boundCond('Dirichlet','Dirichlet',0,0);% Dichlet BC
refArea = [];
refArea = [0.2 1.8]; %refArea = [4/3 8/3];
obj.ThbRefinement1DML(1,refArea,f);
% refArea2 = [2/3 7/3];%[3*pi/8 7*pi/8];
% obj.ThbRefinement1DML(2,refArea2,f);
% refArea3 = [4*pi/8 6*pi/8 ];
% obj.ThbRefinement1DML(3,refArea3,f);

[Stiffn, rhs, iLvl,iBasisFctInd] = assemblePoissThbMl(obj,refArea,f);

y = solveSyst(obj,Stiffn,rhs,iLvl,iBasisFctInd,dBC);

uh =  generSolThb(obj,y);
%hold on;
%plot(obj.getAllKnots,0.01,'k*', 'markers',4)

%fplot(g,[obj.levelBas{1}.a obj.levelBas{1}.b],'b')
%errorEst(uh,g,obj);
[H1err, L2err, Enerr] = errCalc(obj,g,y,iBasisFctInd,iLvl);
errExport(H1err,L2err,Enerr,obj)
end
 