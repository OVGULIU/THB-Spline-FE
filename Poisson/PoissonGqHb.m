clc, clear all, close all
a = 0;
b = 10;
p = 1;
N = 5;
resol = 0.01;
lvl = 2;
obj = hbSplBasML(a,b,p,N,resol,lvl);
f = @(x) (x).^(1/3);
    % change generation of Points!
Points = zeros(obj.levelBas{1}.n,2); % not needed
Points(:,1) = linspace(0,10, size(Points,1) );
Points(:,2) = f(2*pi*Points(:,1));


cBas = obj.levelBas{1};
fBas = obj.levelBas{2};
refArea = [4 8];
[U, Ubar, Points, Qw] = HbRefinement1D(cBas,fBas,refArea,Points);

if(isempty(refArea))
    nOE = N;
    nOF = cBas.n;
else
nOE =N+(refArea(2) - refArea(1))/cBas.knotspan; % number of elements
nOF = length(cBas.activeIndex) +length(fBas.activeIndex); % number o functions
end
Stiffn = zeros(length(cBas.activeIndex) +length(fBas.activeIndex)+1); %basis.n % length(cBas.activeIndex) +length(fBas.activeIndex) 
elStiff = zeros(cBas.p +2); % 
% Ax = b
% Lapl(u) = f
ngp = obj.levelBas{1}.p+3;

rhs = zeros(nOF+1,1); % basis.n number of basis functions!
elRhs =  zeros(cBas.p+2,1);
%allKnots = basis.getAllKnots;
allKnots = unique(obj.getAllKnots);

% number of elements: N+(refArea(2) - refArea(1))/cBas.knotspan
for k = 1 : nOE % loop over elements
    [s,w]=lgwt(ngp,allKnots(k),allKnots(k+1));
    bVal = []; % zeros(ngp, basis.p+1); % basis evaluation
    gradVal = []; % zeros(ngp,basis.p+1); % derivative evaluation
    for j = 1:length(s) %basis.evalDersBasis(s(j))% not yet fully tested!
        temp = obj.evalDersBasis(s(j));%DersBasisFuns(k,s(j),basis.p,basis.knotVector,1) % replace by method of class!
        bVal(j,:) = temp(1,:);
        gradVal(j,:) = temp(2,:); % 
    end
    elRhs = zeros(cBas.p+2,1);
    elStiff = zeros(cBas.p +2);
    for l = 1 : size(bVal,2) % cBas.p+1
        elRhs(l) = sum(w.*f(s).*bVal(:,l));
        elStiff(l,l) = sum(w.*gradVal(:,l).^2);
        for kk = l+1 : size(bVal,2) % cBas.p +1
            elStiff(l,kk) = sum(w.*gradVal(:,l).*gradVal(:,kk));
            elStiff(kk,l) = elStiff(l,kk);
        end
          
            
    end
    rhs(k:k+ cBas.p+1)= rhs(k:k+ cBas.p+1) + elRhs;
    Stiffn(k:k+cBas.p+1,k:k+cBas.p+1) = Stiffn(k:k+cBas.p+1,k:k+cBas.p+1) + elStiff;
     
end
rhs_t = rhs(1:end-1);
Stif_t = Stiffn(1:end-1,1:end-1);
%% BC with Lagrange multipliers
A = zeros(nOE+obj.levelBas{1}.p +1);
b = zeros(nOE+obj.levelBas{1}.p +1,1);
A(1,2) = 1;
A(2,1) = 1;
A(2:end,2:end) = Stif_t;
b(1,1) = 1; % Dichlet BC
b(2:end) = rhs_t;

u = A\b; % use sum u * basis.functions as a curve,
y = u(2:end);
x = allKnots;%linspace(cBas.a,cBas.b,nOE+obj.levelBas{1}.p);
Points = [x' y];
% define as method of the class bSplBas, input parameter Points
hbKnotVector = allKnots;
for k = 1 : cBas.p
    hbKnotVector = [cBas.a hbKnotVector cBas.b];
end % cBas.n
ImpointCurvePlot(nOF,cBas.sP,cBas.p,hbKnotVector,cBas.plotVector,Points)



