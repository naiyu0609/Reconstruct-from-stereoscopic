# Reconstruct-from-stereoscopic
NTUST Computer Vision and Applications

## Reconstruct 3D from stereoscopic side-by-side images

1. Write a program for reconstructing 3D points from stereoscopic images, then, output a 3D XYZ file.
2. The intrinsic and extrinsic parameters of both images are given in CalibrationData .txt In this project , you need to write a program for importing side by side image sequences, and analyzing images to create a 3D .xyz file A fundamental matrix is also given for assisting you to find the corresponding features in left and right images Once corresponding features are determined, please calculate their 3D, then store them as a .xyz. Please reject all outliers by verifying their re-projection error.
3. In each frame, you need to split it into left and right images. Try to pick out the bright est pixel in each row in Left and find out its corresponding point in Right ,as well as inverse direction, under epipolar geometry Finally calculate 3D by “direct triangulation” as mentioned in lecture X Y Z in each line of a text file with .xyz extension

#### 本專案是將兩個不同角度(左右)的相機照出的影像去做計算算出3D的結構圖

首先我必須對圖像集進行預處理，因為我必須將物體跟背景做分離的處理，最後得到每條掃描線的圖像集，為了方便做確認我將每條掃描線合併成一張影像(如下圖)，確保我真的將物體與背景分離。
![](https://github.com/naiyu0609/Reconstruct-from-stereoscopic/blob/main/png/1.PNG)

後續因為我得到了每條掃描線的左右對應圖(如下圖，其中一條掃描線，依照SBS_115.jpg做出)，接下來必須找到左右對應圖中的特徵點集合，而使用的方式是利用x'Fx=0這個式子去做計算。
![](https://github.com/naiyu0609/Reconstruct-from-stereoscopic/blob/main/png/2.PNG)

而概念是利用Fundamental Matrix去計算出左圖每個特徵點的Epipolar Line，之後右圖每個特徵點對此Epipolar Line做距離的估計(利用x'Fx=0)，為了確保不要最近的特徵點距離直線還是太遠，我在程式裡有設計一個閥值去做處理。
![](https://github.com/naiyu0609/Reconstruct-from-stereoscopic/blob/main/png/3.PNG)

因為已知xx'PP'，所以可以利用上述已知求出此特徵點對的3D座標點，當然這個做法要對每個特徵點對做處理，還有要找出特徵點對，因此時間的部分可能會花上一陣子，依照我的電腦做處理，平均時間落在2.5分鐘~3分鐘，此時間為單向處理，就是說依照左圖找右圖特徵點方式，但程式運作也有右圖找左圖特徵點，因此時間部分總花費來到5分鐘~6分鐘左右的時間。
![](https://github.com/naiyu0609/Reconstruct-from-stereoscopic/blob/main/png/4.PNG)

最後3D結構的部分如下圖所示，因為只有兩個角度的關係，細節的部份以及完整頭像並沒有完全的體現，但確實可以觀察到3D的結構出現。
![](https://github.com/naiyu0609/Reconstruct-from-stereoscopic/blob/main/png/5.PNG)
