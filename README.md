Mapguide Open Source
===
#### Versions

brucepc/mapguide:latest    
[![](https://images.microbadger.com/badges/image/brucepc/mapguide.svg)](https://microbadger.com/images/brucepc/mapguide "Get your own image badge on microbadger.com")

brucepc/mapguide:2.6      
[![](https://images.microbadger.com/badges/image/brucepc/mapguide:2.6.svg)](https://microbadger.com/images/brucepc/mapguide:2.6 "Get your own image badge on microbadger.com")

How to use
===
```bash
docker pull brucepc/mapguide:[version]
docker run -ti -d brucepc/mapguide:[version]
```
Entry points params:   
===
+ --no-tomcat        ``doesn't start tomcat server``   
+ --no-apache        ``doesn't start the apache server``   
+ --only-mapguide    ``start only mapguide server``  
+ --crash-time       ``time to start mapguide after crash``

```bash
docker run -ti brucepc/mapguide --no-tomcat
```
Exposed ports:
===
+ 8008 Apache server
+ 8009 Tomcat server

