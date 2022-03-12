clear,clc
%initial
disp('initial')
tic%�p�ɶ}�l
LK=[1496.880651 0.000000 605.175810;
    0.000000 1490.679493 338.418796;
    0.000000 0.000000 1.000000];%����K
LRT=[1.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0;
    0.0 0.0 1.0 0.0];%����RT
LP=LK*LRT;%%����P
RK=[1484.936861 0.000000 625.964760;
    0.000000 1480.722847 357.750205;
    0.000000 0.000000 1.000000];%�k��K
RRT=[0.893946 0.004543 0.448151 -186.807456;
    0.013206 0.999247 -0.036473 3.343985;
    -0.447979 0.038523 0.893214 45.030463];%�k��RT
RP=RK*RRT;%�k��P
FM=[0.000000191234 0.000003409602 -0.001899934537;
    0.000003427498 -0.000000298416 -0.023839273818;
    -0.000612047140 0.019636148869 1.000000000000];%Fundamental Matrix
imageDir = fullfile('.\SidebySide');%Dataset����Ƹ��|
imageSet = imageDatastore(imageDir);%Dataset
imageProDir = fullfile('.\SidebySidePro\');%Dataset�B�z�᪺��Ƹ��|
numfile=numel(imageSet.Files);%�p��h�ֹ�
mkdir(imageProDir);%�سB�z��dataset
%%
clc
disp('calculate')
for i=1:numel(imageSet.Files)%��C�i�ϰ��B�z(���p�g���I)
    clc
    disp(['Step1-Preprocessing/' num2str(round(i*100/numfile)) '%']);
    I=readimage(imageSet,i);%Ū��
    for j=1:720
        %���B�z����
        max=0;%��̤j�ȥ�
        maxcheck=0;%�T�O�u���@���I
        for k=1:1280
            if I(j,k)>max%�p�G����j����
                max=I(j,k);%����
            end
        end
        for k=1:1280
            if maxcheck==0&&I(j,k)==max&&I(j,k)>95%���̤j�Ȫ��I�T�w�ȭn�j��֭�95
                I(j,k)=255;%�N���I�ܬ����I
                maxcheck=1;%�T�w����I �����L�P�Ȥ���
            else
                I(j,k)=0;%��L�]�����I
            end
        end
        %�B�z�k�ϨB�J�P�W���@��
        max=0;
        maxcheck=0;
        for k=1281:2560
            if I(j,k)>max
                max=I(j,k);
            end
        end
        for k=1281:2560
            if maxcheck==0&&I(j,k)==max&&I(j,k)>95
                I(j,k)=255;
                maxcheck=1;
            else
                I(j,k)=0;
            end
        end
    end
    imwrite(I,[imageProDir,int2str(i),'.jpg']);%��i�v���B�z�����x�s
end
imageProSet = imageDatastore(imageProDir);%Data�B�z���᪺Dataset
Finalimage = readimage(imageProSet,1);%���@�i���㪺�¥ռv��
for i=1:numel(imageProSet.Files)%Ū�C�����y�u�i�@�i��
    I=readimage(imageProSet,i);
    for j=1:720
        for k=1:2560
            if  I(j,k)==255
                Finalimage(j,k)=255;
            end
        end
    end
end
imwrite(Finalimage,'LR.jpg');%���k���X����
imwrite(Finalimage(:,1:1280),'L.jpg');%��W���Ϥ@�i
imwrite(Finalimage(:,1281:2560),'R.jpg');%��W�k�Ϥ@�i
%%
voxelco=[];%��X3D�y�ХΪ��ܼ�
%���Ϲ�k�Ϫ�3D�y�ЭȦ��p
for k=1:numel(imageProSet.Files)%Ū�J�C�i�B�z�᪺�v��
    clc
    disp(['Step2-calculate 3D location from L to R/' num2str(round(k*100/numfile)) '%']);
    P=readimage(imageProSet,k);%Ū�v��
    PL=P(:,1:1280);%���Υ��v��
    PR=P(:,1281:2560);%���Υk�v��
    for yl=1:720
        for xl=1:1280%�索�ϱ��y
            if PL(yl,xl)==255%�����I
                l=FM*[xl yl 1]';%�i��epipolar line�p��
                min=5000;%�n���Z���o���u�̪��I
                xr=0;
                yr=0;
                for i=1:720
                    for j=1:1280%��k�ϱ��y
                        if PR(i,j)==255&&abs(l'*[j i 1]')<min%�Y�k�ϧ����I�S�Z���ܧ��
                            min=abs(l'*[j i 1]');%�����̤p�ȷ�@������I
                            yr=i;%����I
                            xr=j;%����I
                        end
                    end
                end
                if abs(min)<0.1%�T�O��쪺�I���|�ӻ� ����i��3D�y�Ц���
                    A=[xl*LP(3,:)-LP(1,:);
                       yl*LP(3,:)-LP(2,:);
                       xr*RP(3,:)-RP(1,:);
                       yr*RP(3,:)-RP(2,:);];
                   [U,S,V]=svd(A);
                   V=V/V(4,4);
                   voxelco=[voxelco;round(V(1,4)) round(V(2,4)) round(V(3,4))];%�s�J3D�y�Ц��⪺�ܼƥH�K��X
                end
            end
        end
    end
end
%%
%�k�Ϲ索�Ϫ�3D�y�ЭȦ��p
%�@�k��W�B�J�@��
for k=1:numel(imageProSet.Files)
    clc
    disp(['Step3-calculate 3D location from R to L/' num2str(round(k*100/numfile)) '%']);
    P=readimage(imageProSet,k);
    PL=P(:,1:1280);
    PR=P(:,1281:2560);
    for yr=1:720
        for xr=1:1280
            if PR(yr,xr)==255
                l=FM'*[xr yr 1]';
                min=5000;
                xl=0;
                yl=0;
                for i=1:720
                    for j=1:1280
                        if PL(i,j)==255&&abs(l'*[j i 1]')<min
                            min=abs(l'*[j i 1]');
                            yl=i;
                            xl=j;
                        end
                    end
                end
                if abs(min)<0.1
                    A=[xr*RP(3,:)-RP(1,:);
                       yr*RP(3,:)-RP(2,:);
                       xl*LP(3,:)-LP(1,:);
                       yl*LP(3,:)-LP(2,:);];
                   [U,S,V]=svd(A);
                   V=V/V(4,4);
                   voxelco=[voxelco;round(V(1,4)) round(V(2,4)) round(V(3,4))];
                end
            end
        end
    end
end
%%
name=append('B10607044.xyz');
dlmwrite(name,voxelco,'\t')%��Xxyz��
clc
disp('done')
toc%�p�ɵ���