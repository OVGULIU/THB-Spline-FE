classdef thbSplBas < hbSplBas
     properties
        truncIndex = []; % save which basis functions are truncated
        trunc = [];
     end
     methods (Access = public)
         function obj = thbSplBas(a,b,p,N,resol)
            % constructor for class
            % a, b, p, knotspan, resol
            if nargin >0
                obj.a = a;
                obj.b = b;
                obj.N = N;
                obj.p = p;
                obj.resol = resol;
                
            end
                obj.knotspan = (obj.b-obj.a)/obj.N;
                obj.knotVector = ConstrKnotVector(obj.a,obj.b,obj.knotspan,obj.p);
                obj.plotVector = [obj.knotVector(1):obj.resol:obj.knotVector(end)];
                obj.sP = size(obj.plotVector,2);
                obj.m = size(obj.knotVector,2);
                obj.n = obj.m - obj.p - 1;
                obj.activeKnots = [];%obj.getAllKnots;
                obj.activeIndex = [];%[0 : obj.n-1]; % function index
            function knotVector = ConstrKnotVector(a,b,h1,p)
                % simple constructor for knot vector
                temp = (b-a)/h1;
                assert( rem(temp,1) == 0,'Use values a,b,h1 such that b-a/h1 is an integer.')
                m = temp + 2*p+1;
                knotVector = zeros(1,m);
                knotVector(1:p) = a;
                knotVector(p+1:m-p) = a:h1:b;
                knotVector(m-p+1:end) = b;
            end
         end
         %% change so that truncated Basis functions are used
         function C = generBasisRed(obj,fBas) % überladen, 
            % more efficient method possible? Yes, generate both bases,
            % deactivate and truncate and return
            %% calculate only active, truncated basis functions!
            C = zeros(obj.sP,obj.n);
            tableSpan = lookUpTableSpan(obj);
            for i = 1 : obj.sP
                startX = tableSpan(i) - tableSpan(1) +1;
                bas_temp = BasisFuns(tableSpan(i),obj.plotVector(i),obj.p,obj.knotVector);
                for j = obj.activeIndex % plot only active basis functions
                    if (ismember(j,obj.truncIndex))
                       % disp('Truncation necessary')
                       %carefull, check this condition again!
                       for k = max(1,2*j-floor(obj.p)) : min(2*j+floor(obj.p/2)+2,size(obj.trunc(:,j+1)))
                            if(obj.trunc(k,j+1) > 0 ) %(p,m,U,i,u)
                                bas_temp2 = OneBasisFun(fBas.p,fBas.m,fBas.knotVector,k-1,obj.plotVector(i));
                                    C(i,j+1) = C(i,j+1)+ obj.trunc(k,j+1)*bas_temp2(1);
                            %else
                             %   disp('Unnecessary.')
                            end
                        end
                        continue;
                    else
                        if (j-tableSpan(i) + obj.p  ) < obj.p+1 && tableSpan(i) - j  < obj.p+1
                            tmp = mod(j+1 - startX, (obj.p+1))+1;  % temporary solution
                            C(i,j+1) = bas_temp(1,tmp);
                        end
                    end
                end
            end
            
         end
%           function cnt = getIndexU(obj,u) % returns index as in lookUpTableSpan
%             assert( (obj.a <= u) & (u <= obj.b),'u out of range of knotVector.');
%             if(u == obj.a) % is this correct?
%                 cnt = obj.p;
%                	return 
%             end
%             if(u == obj.b)
%                 cnt = obj.m-obj.p-1;%% work around, think of better one!
%                 return;
%             end
%             left = obj.a;
%             cnt = 0;
%             while(u >= left) % changed to >= to get a new index for first 
%                 cnt = cnt + 1;
%                 left = obj.knotVector(cnt+2);
%             end
%             if (ismember(cnt,obj.truncIndex))
%                 disp('Truncated function')
%             end
%             
%             
%         end
         
         
         
         function setCharM(obj) %Not yet fully tested
              obj.charM = sparse(obj.n, obj.n); % instead of zeros
         for k = obj.activeIndex 
                obj.charM(k+1,k+1) = 1;
         end
         end
     end
end