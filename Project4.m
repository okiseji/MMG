% A=[1,2,3;4,5,6;7,8,9];
% Without_P=LUnoP(A)
% [With_P,P]=LUwpP(A)
% LU=lu(A)
B=[4,2,3;2,3,2;3,2,3];
R=cholesky(B)
T=chol(B)
T'*T
R'*R
function A=LUnoP(A)
    [m,~]=size(A);
    for i=1:m-1
        for j=i+1:m
            A(j,i)=A(j,i)/A(i,i);
            A(j,i+1:m)=A(j,i+1:m)-A(i,i+1:m)*A(j,i);
        end
    end
end
function [A,P]=LUwpP(A)
    [m,~]=size(A);
    P=[1:m]';
    for i=1:m-1
        for j=i+1:m
            [~,index]=max(A(i:m,i));
            A([i,index],:)=A([index,i],:);
            P([i,index],:)=P([index,i],:);
            A(j,i)=A(j,i)/A(i,i);
            A(j,i+1:m)=A(j,i+1:m)-A(i,i+1:m)*A(j,i);
        end
    end
end
function R=cholesky(A)
    [m,~]=size(A);
    L=zeros(m,m);
    row=1;col=1;
    j=1;
    for i=1:m
        L(row,col)=sqrt(A(1,1));
        if(m~=1)
            L(row+1:end,col)=A(j+1:m,1)/sqrt(A(1,1));
            A=(A(j+1:m,j+1:m)-L(row+1:end,col)*L(row+1:end,col)');
            [m,~]=size(A);
            row=row+1;
            col=col+1;
        end
    end
    R=L';
end
    