## Android Repackaged App Detection System  
  
+ Grab apk files from Google Play and third-party marketplaces  
+ Generate smali code and .dot data flow analysis graph  
+ Compare the graph similarity to find the repackaged apps  
+ Users can upload apk files and get the result.  
  
### Dependencies  
  
+ [Akdeniz/google-play-crawler](https://github.com/Akdeniz/google-play-crawler)  
    + Java  
    + For Google Play Market apps crawling  
+ [mssun/android-apps-crawler](https://github.com/mssun/android-apps-crawler)  
    + Python  
    + For Third Party Market apps crawling  
+ [saaf - Static Android Analysis Framework](https://code.google.com/p/saaf/)  
    + Java  
    + A static analyzer for Android apk files  
+ [NetworkX](https://networkx.github.io/)  
    + Python  
    + <https://github.com/networkx/networkx>  
    + For Data Dependency Graph (Genrated by SAAF) analysis  
    + For Subgraph Isomorphism Detection  
+ [D3.js](http://d3js.org/)  
    + For graph visualization  
+ [node.js](http://nodejs.org/)  
    + For web server & user interface  
