
 fileName = '/home/laptop/Documents/_mat_files/output/AdaptErrp3Prec9.txt';
 if exist(fileName) == 2
     delete(fileName);
 end
 fileID = fopen(fileName,'a');
 fprintf(fileID,'N, H1err, L2err, Enerr,  obj.nOF refArea \n')
 fclose(fileID)
 
N = 0;
for k = 0 : 5
    N = 10*2^k;
    PoissonGqThbMl(N);
end