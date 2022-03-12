clear,clc
%initial
disp('initial')
tic%計時開始
LK=[1496.880651 0.000000 605.175810;
    0.000000 1490.679493 338.418796;
    0.000000 0.000000 1.000000];%左圖K
LRT=[1.0 0.0 0.0 0.0;
    0.0 1.0 0.0 0.0;
    0.0 0.0 1.0 0.0];%左圖RT
LP=LK*LRT;%%左圖P
RK=[1484.936861 0.000000 625.964760;
    0.000000 1480.722847 357.750205;
    0.000000 0.000000 1.000000];%右圖K
RRT=[0.893946 0.004543 0.448151 -186.807456;
    0.013206 0.999247 -0.036473 3.343985;
    -0.447979 0.038523 0.893214 45.030463];%右圖RT
RP=RK*RRT;%右圖P
FM=[0.000000191234 0.000003409602 -0.001899934537;
    0.000003427498 -0.000000298416 -0.023839273818;
    -0.000612047140 0.019636148869 1.000000000000];%Fundamental Matrix
imageDir = fullfile('.\SidebySide');%Dataset的資料路徑
imageSet = imageDatastore(imageDir);%Dataset
imageProDir = fullfile('.\SidebySidePro\');%Dataset處理後的資料路徑
numfile=numel(imageSet.Files);%計算多少圖
mkdir(imageProDir);%建處理後dataset
%%
clc
disp('calculate')
for i=1:numel(imageSet.Files)%對每張圖做處理(找到雷射的點)
    clc
    disp(['Step1-Preprocessing/' num2str(round(i*100/numfile)) '%']);
    I=readimage(imageSet,i);%讀圖
    for j=1:720
        %先處理左圖
        max=0;%找最大值用
        maxcheck=0;%確保只找到一個點
        for k=1:1280
            if I(j,k)>max%如果找到更大的值
                max=I(j,k);%替換
            end
        end
        for k=1:1280
            if maxcheck==0&&I(j,k)==max&&I(j,k)>95%找到最大值的點確定值要大於閥值95
                I(j,k)=255;%將此點變為白點
                maxcheck=1;%確定找到點 之後其他同值不看
            else
                I(j,k)=0;%其他設為黑點
            end
        end
        %處理右圖步驟與上面一樣
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
    imwrite(I,[imageProDir,int2str(i),'.jpg']);%整張影像處理完做儲存
end
imageProSet = imageDatastore(imageProDir);%Data處理完後的Dataset
Finalimage = readimage(imageProSet,1);%做一張完整的黑白影像
for i=1:numel(imageProSet.Files)%讀每條掃描線進一張圖
    I=readimage(imageProSet,i);
    for j=1:720
        for k=1:2560
            if  I(j,k)==255
                Finalimage(j,k)=255;
            end
        end
    end
end
imwrite(Finalimage,'LR.jpg');%左右的合成圖
imwrite(Finalimage(:,1:1280),'L.jpg');%單獨左圖一張
imwrite(Finalimage(:,1281:2560),'R.jpg');%單獨右圖一張
%%
voxelco=[];%輸出3D座標用的變數
%左圖對右圖的3D座標值估計
for k=1:numel(imageProSet.Files)%讀入每張處理後的影像
    clc
    disp(['Step2-calculate 3D location from L to R/' num2str(round(k*100/numfile)) '%']);
    P=readimage(imageProSet,k);%讀影像
    PL=P(:,1:1280);%分割左影像
    PR=P(:,1281:2560);%分割右影像
    for yl=1:720
        for xl=1:1280%對左圖掃描
            if PL(yl,xl)==255%找到白點
                l=FM*[xl yl 1]';%進行epipolar line計算
                min=5000;%要找到距離這條線最近的點
                xr=0;
                yr=0;
                for i=1:720
                    for j=1:1280%對右圖掃描
                        if PR(i,j)==255&&abs(l'*[j i 1]')<min%若右圖找到白點又距離變更近
                            min=abs(l'*[j i 1]');%替換最小值當作找到更近點
                            yr=i;%找到點
                            xr=j;%找到點
                        end
                    end
                end
                if abs(min)<0.1%確保找到的點不會太遠 之後進行3D座標估算
                    A=[xl*LP(3,:)-LP(1,:);
                       yl*LP(3,:)-LP(2,:);
                       xr*RP(3,:)-RP(1,:);
                       yr*RP(3,:)-RP(2,:);];
                   [U,S,V]=svd(A);
                   V=V/V(4,4);
                   voxelco=[voxelco;round(V(1,4)) round(V(2,4)) round(V(3,4))];%存入3D座標估算的變數以便輸出
                end
            end
        end
    end
end
%%
%右圖對左圖的3D座標值估計
%作法跟上步驟一樣
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
dlmwrite(name,voxelco,'\t')%輸出xyz檔
clc
disp('done')
toc%計時結束