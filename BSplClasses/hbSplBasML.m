classdef hbSplBasML < handle
    properties %(GetAccess = public, SetAccess = private)    
        levelBas = [];
        basis0 = [];
        level = 2; %% add variable for the number of active basis functions
        nOF = 0;% basisFunctionIndex = [];
        nOE = 0;
    end
     properties (Hidden = true, SetAccess = private)
        foo = 1
    end
     methods (Access = public)
        function obj = hbSplBasML(a,b,p,N,resol,level)
            % constructor for class
            % a, b, p, knotspan, resol
            if nargin >0
                assert(level >= 1, 'The number of levels has to be a positive integer.');
            for k = 1 : level
                obj.levelBas{1,k} = hbSplBas(a,b,p,N*2^(k-1),resol/2^(k-1)); %resol needed for solution plot!
            end % set index of level 0 to active
                obj.levelBas{1}.activeIndex = [0 : obj.levelBas{1}.n-1];
                obj.levelBas{1}.activeKnots = obj.levelBas{1}.getAllKnots;
                obj.basis0 = obj.levelBas{1,1};
                obj.level = level;
                obj.nOF = obj.levelBas{1}.n;
                obj.nOE = length(obj.levelBas{1}.getAllKnots) -1;
            end
              
        end
        

        
        function x = getAllKnots(obj) % do we want the multiple knots as marking points for level change?
            x = []; %% TEST!!!
            for k = 1: obj.level
                if(isempty(obj.levelBas{k}.refArea)) % wrong, what about trivial refinement
                    if( k > 1)
                    x = [x obj.levelBas{k-1}.refArea(1):obj.levelBas{k}.knotspan:obj.levelBas{k-1}.refArea(2)];
                    break;
                    else
                        x = unique(obj.levelBas{k}.knotVector);
                        return;
                    end
                end
                x = [x obj.levelBas{k}.knotVector(obj.levelBas{k}.p):obj.levelBas{k}.knotspan:obj.levelBas{k}.refArea(1)];
                
            end
            if(obj.levelBas{k-1}.refArea(2) ~= obj.levelBas{k-1}.b)
            for l = 1:k-1
                x = [x obj.levelBas{k-l}.refArea(2):obj.levelBas{k-l}.knotspan:obj.levelBas{k-l}.b];
            end
            end    
            x = unique(x);
        end
%         function v = getIndices(obj)
%             % see also lookUpTableSpan
%             v.knotVector = obj.getAllKnots;
%             v.allKnotIndex = [0:length(v.knotVector)];
%             %v.activeKnots = [obj.p : obj.n-1];
%             v.basisFunctionIndex = obj.basisFunctionIndex;
%         end
        function [lvl, BasisFctInd] = getAllActiveFct(obj)
            % returns all active basis functions in correct order
            % just for 2 levels, 
            % TEST!
            % generalize for more levels
            BasisFctInd = [];
            lvl = [];
            fActInd = obj.levelBas{2}.activeIndex;
            cActInd = obj.levelBas{1}.activeIndex;
            if(obj.levelBas{1}.refArea(2) == obj.levelBas{1}.b)
                BasisFctInd = [cActInd fActInd];
                lvl = [ones(1,length(cActInd)) 2*ones(1,length(fActInd))];
            elseif(obj.levelBas{1}.refArea(1) == obj.levelBas{1}.a)
                BasisFctInd = [fActInd cActInd];
                lvl = [ 2*ones(1,length(fActInd)) ones(1,length(cActInd))];
            else
            for k = 1 : length(cActInd)-1
                BasisFctInd = [BasisFctInd k-1];
                lvl = [lvl 1];
                if(k < cActInd(k+1))
                    BasisFctInd = [BasisFctInd fActInd];
                    lvl = [lvl 2*ones(1,length(fActInd))];
                    k = (k+1);
                    break
                end
            end
            BasisFctInd = [BasisFctInd cActInd(k:end)];
            lvl = [lvl ones(1,length(cActInd(k:end)))];
            end
        end
        
        
        function [lvl, BasisFctInd] = getActiveFctIndU(obj,u)
            lvl = [];
            BasisFctInd = [];
            for k = 1 : obj.level
                indU = obj.levelBas{k}.getIndexU(u);
                indSet = (indU-obj.levelBas{k}.p) :indU; % index of act fcts
                actSet = intersect(indSet,obj.levelBas{k}.activeIndex);
                lvl = [lvl, k*ones(1,length(actSet))];
                BasisFctInd = [ BasisFctInd , actSet];
            end
        end
        
        function [lvl,BasisFctInd,basVal] = evalBasisLvl(obj,u)
            basVal = [];
            [lvl, BasisFctInd] = getActiveFctIndU(obj,u);
            for k = 1 : length(BasisFctInd)
                index = BasisFctInd(k); % p,m,U,i,u
                basValues = OneBasisFun(obj.levelBas{lvl(k)}.p,obj.levelBas{lvl(k)}.m,...
                obj.levelBas{lvl(k)}.knotVector,index,u);
                basVal = [basVal basValues];
            end
        end
        
        function basVal = evalBasis(obj,u)
             [~,~,basVal] = obj.evalBasisLvl(u);
        end
        
        function [lvl,BasisFctInd,basVal] = evalDersBasisLvl(obj,u)
            basVal = [];
            [lvl, BasisFctInd] = getActiveFctIndU(obj,u);
            for k = 1 : length(BasisFctInd)
                index = BasisFctInd(k);%(p,m,U,i,u,n)
                basValues = DersOneBasisFun(obj.levelBas{lvl(k)}.p,obj.levelBas{lvl(k)}.m,...
                obj.levelBas{lvl(k)}.knotVector,index,u,1);
                basVal = [basVal basValues'];
            end
        end
        function basVal = evalDersBasis(obj,u)
           [~,~,basVal] = obj.evalDersBasisLvl(u);
        end
        
        function [U, Ubar, Points, Qw] = HbRefinement1DML(obj,rLevel,refArea,f)
            % Test: hb refinement!
            % maybe get rid of global index basisFunctionIndex7
            % function f not needed, as Points are not needed
            assert(rLevel < obj.level, 'Error: rLevel >= obj.level');
            Points = zeros(obj.levelBas{rLevel}.n,2); % not needed
            Points(:,1) = linspace(obj.levelBas{rLevel}.a,obj.levelBas{rLevel}.b, size(Points,1));
            Points(:,2) = f(2*pi*Points(:,1));
            
            cBas = obj.levelBas{rLevel};
            fBas = obj.levelBas{rLevel+1};
            [U, Ubar, Points, Qw] = HbRefinement1D(cBas,fBas,refArea, Points);
            % obj.basisFunctionIndex = [1:length(obj.levelBas{rLevel}.activeIndex)+length(obj.levelBas{rLevel+1}.activeIndex)];
        end
     end
end