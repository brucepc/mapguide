FROM ubuntu:12

ENV TEMPDIR=/tmp/build_mapguide
ENV URL="http://download.osgeo.org/mapguide/releases/2.6.0/Release/ubuntu12"
ENV FDOVER_MAJOR_MINOR=3.9
ENV FDOVER_MAJOR_MINOR_REV=${FDOVER_MAJOR_MINOR}.0
ENV FDOBUILD=7090
ENV FDOARCH=i386
ENV FDOVER=${FDOVER_MAJOR_MINOR_REV}-${FDOBUILD}_${FDOARCH}
ENV MGVER_MAJOR_MINOR=2.6
ENV MGVER_MAJOR_MINOR_REV=${MGVER_MAJOR_MINOR}.0
ENV MGBUILD=8316
ENV MGARCH=i386
ENV MGVER=${MGVER_MAJOR_MINOR_REV}-${MGBUILD}_${MGARCH}

ENV DEFAULT_ADMIN_PORT=2810
ENV DEFAULT_CLIENT_PORT=2811
ENV DEFAULT_SITE_PORT=2812

ENV DEFAULT_HTTPD_PORT=8008
ENV DEFAULT_TOMCAT_PORT=8009
ENV MG_PATH=/usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}

RUN apt-get update && apt-get -y install libexpat1 \
	libssl1.0.0 \
	odbcinst \
	unixodbc \
	libcurl3 \
	libxslt1.1;\
	rm -rf /var/lib/apt/lists/* ; \
	rm -rf /var/lib/apt/archives/*

RUN mkdir -p ${TEMPDIR};\
	cd ${TEMPDIR}

RUN curl --progress-bar -L \
    ${URL}/fdo-{core,sdf,shp,sqlite,gdal,ogr,kingoracle,rdbms,wfs,wms}_${FDOVER}.deb \
    -o "${TEMPDIR}/fdo-#1_${FDOVER}.deb"; \
    dpkg -E -G --install fdo-core_${FDOVER}.deb \
    fdo-sdf_${FDOVER}.deb \
    fdo-shp_${FDOVER}.deb \
    fdo-sqlite_${FDOVER}.deb \
    fdo-gdal_${FDOVER}.deb \
    fdo-ogr_${FDOVER}.deb \
    fdo-kingoracle_${FDOVER}.deb \
    fdo-rdbms_${FDOVER}.deb \
    fdo-wfs_${FDOVER}.deb \
    fdo-wms_${FDOVER}.deb; rm -f ./fdo*

RUN curl --progress-bar -L \
    ${URL}/mapguideopensource-{platformbase,coordsys-lite,common,server,webextensions,httpd}_${MGVER}.deb \
    -o "${TEMPDIR}/mapguideopensource-#1_${MGVER}.deb";\
    dpkg -E -G --install mapguideopensource-platformbase_${MGVER}.deb \
    mapguideopensource-coordsys-lite_${MGVER}.deb \
    mapguideopensource-common_${MGVER}.deb \
    mapguideopensource-server_${MGVER}.deb \
    mapguideopensource-webextensions_${MGVER}.deb \
    mapguideopensource-httpd_${MGVER}.deb; \

COPY providers.xml /tmp/providers.xml

RUN perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg; s/\$\{([^}]+)\}//eg' /tmp/providers.xml | tee /usr/local/fdo-${FDOVER_MAJOR_MINOR_REV}/lib/providers.xml

WORKDIR ${MG_PATH}
RUN chmod 777 webserverextensions/www/TempDir
