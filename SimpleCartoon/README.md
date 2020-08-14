![](SimpleCartoon.png)

十分简易的卡通效果，单纯的后期描边+阴影。
参考了《Unity Shader入门精要》和[Unity Shader-描边效果](https://blog.csdn.net/puppet_master/article/details/54000951)

描边使用后处理，为了区别需要描边和不需要描边的物件而使用了额外一个摄像机。然后使用深度和法线去判断边界，主要是为了区别下面两种情况。
![](SimpleCartoon01.jpg)
因为没有去考虑模糊的效果，而只想画一条实线边，所以没有按照卷积的算式去算，不过原理是相同的。

阴影用传统的Bilnn-Phong模型为了让阴影有卡通那种比较明显的明暗过度，就使用了灰度图。让暗一些的阴影占小一点是为了能更多的表现亮面。
![](SimpleCartoon02.jpg)
