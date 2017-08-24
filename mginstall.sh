#!/usr/bin/env bash

TEMPDIR=/tmp/build_mapguide
URL_ROOT="http://download.osgeo.org/mapguide/releases/2.6.1/Final"
URL_PART="ubuntu12"
URL="$URL_ROOT/$URL_PART"
#URL="http://192.168.0.5/downloads/ubuntu12"
FDOVER_MAJOR_MINOR=3.9
FDOVER_MAJOR_MINOR_REV=${FDOVER_MAJOR_MINOR}.0
FDOBUILD=7202
FDOARCH=i386
FDOVER=${FDOVER_MAJOR_MINOR_REV}-${FDOBUILD}_${FDOARCH}
MGVER_MAJOR_MINOR=2.6
MGVER_MAJOR_MINOR_REV=${MGVER_MAJOR_MINOR}.1
MGBUILD=8732
MGARCH=i386
MGVER=${MGVER_MAJOR_MINOR_REV}-${MGBUILD}_${MGARCH}
INSTALLER_TITLE="MapGuide Open Source Ubuntu installer"

DEFAULT_SERVER_IP="127.0.0.1"

DEFAULT_ADMIN_PORT=2810
DEFAULT_CLIENT_PORT=2811
DEFAULT_SITE_PORT=2812

DEFAULT_HTTPD_PORT=8008
DEFAULT_TOMCAT_PORT=8009

csmap_choice="full"

server_ip="127.0.0.1"
webtier_server_ip="127.0.0.1"

admin_port=2810
client_port=2811
site_port=2812

httpd_port=8008
tomcat_port=8009

fdo_provider_choice=""

# Must have root
if [[ $EUID -ne 0 ]]; then
    echo "You must run this script with superuser privileges"
    exit 1
fi

while [ $# -gt 0 ]; do    # Until you run out of parameters...
    case "$1" in
        -headless|--headless)
        HEADLESS=1
            #shift
        ;;
        -with-sdf|--with-sdf)
            fdo_provider_choice="$fdo_provider_choice sdf"
            #shift
            ;;
        -with-shp|--with-shp)
            fdo_provider_choice="$fdo_provider_choice shp"
            #shift
            ;;
        -with-sqlite|--with-sqlite)
            fdo_provider_choice="$fdo_provider_choice sqlite"
            #shift
            ;;
        -with-gdal|--with-gdal)
            fdo_provider_choice="$fdo_provider_choice gdal"
            #shift
            ;;
        -with-ogr|--with-ogr)
            fdo_provider_choice="$fdo_provider_choice ogr"
            #shift
            ;;
        -with-kingoracle|--with-kingoracle)
            fdo_provider_choice="$fdo_provider_choice kingoracle"
            #shift
            ;;
        -with-wfs|--with-wfs)
            fdo_provider_choice="$fdo_provider_choice wfs"
            #shift
            ;;
        -with-wms|--with-wms)
            fdo_provider_choice="$fdo_provider_choice wms"
            #shift
            ;;
        -server-ip|--server-ip)
            server_ip="$2"
            webtier_server_ip="$2"
            shift
            ;;
        -admin-port|--admin-port)
            admin_port=$2
            shift
            ;;
        -client-port|--client-port)
            client_port=$2
            shift
            ;;
        -site-port|--site-port)
            site_port=$2
            shift
            ;;
        -httpd-port|--httpd-port)
            httpd_port=$2
            shift
            ;;
        -tomcat-port|--tomcat-port)
            tomcat_port=$2
            shift
            ;;
        -help|--help)
            echo "Usage: $0 (options)"
            echo "Options:"
            echo "  --headless [Install headlessly (skip UI)]"
            echo "  --with-sdf [Include SDF Provider]"
            echo "  --with-shp [Include SHP Provider]"
            echo "  --with-sqlite [Include SQLite Provider]"
            echo "  --with-gdal [Include GDAL Provider]"
            echo "  --with-ogr [Include OGR Provider]"
            echo "  --with-kingoracle [Include King Oracle Provider]"
            echo "  --with-wfs [Include WFS Provider]"
            echo "  --with-wms [Include WMS Provider]"
            echo "  --server-ip [Server IP, default: 127.0.0.1]"
            echo "  --admin-port [Admin Server Port, default: 2810]"
            echo "  --client-port [Client Server Port, default: 2811]"
            echo "  --site-port [Site Server Port, default: 2812]"
            echo "  --httpd-port [HTTPD port, default: 8008]"
            echo "  --tomcat-port [Tomcat Port, default: 8009]"
            exit
            ;;
    esac
    shift   # Check next set of parameters.
done

if [ "$HEADLESS" != "1" ]
then
# Install required packages
apt-get -y install dialog libexpat1 libssl1.0.0 odbcinst unixodbc libcurl3 libxslt1.1
else
# Install required packages
apt-get -y install libexpat1 libssl1.0.0 odbcinst unixodbc libcurl3 libxslt1.1
fi

DIALOG=${DIALOG=dialog}

main()
{
    if [ "$HEADLESS" != "1" ]
    then
        dialog_welcome
        dialog_fdo_provider
        dialog_server
        dialog_webtier
        #dialog_coordsys
    else
        dump_configuration
    fi
    install_fdo
    install_mapguide_packages
    post_install
}

set_server_vars()
{
    set -- $(<$1)
    server_ip=$1
    admin_port=$2
    client_port=$3
    site_port=$4
}

set_webtier_vars()
{
    set -- $(<$1)
    webtier_server_ip=$1
    httpd_port=$2
    tomcat_port=$3
}

dump_configuration()
{
    echo "********* Configuration Summary ************"
    echo " Default Ports (Server)"
    echo "  Admin: ${DEFAULT_ADMIN_PORT}"
    echo "  Client: ${DEFAULT_CLIENT_PORT}"
    echo "  Site: ${DEFAULT_SITE_PORT}"
    echo " Default Ports (WebTier)"
    echo "  Apache: ${DEFAULT_HTTPD_PORT}"
    echo "  Tomcat: ${DEFAULT_TOMCAT_PORT}"
    echo " Configured Ports (Server)"
    echo "  Admin: ${admin_port}"
    echo "  Client: ${client_port}"
    echo "  Site: ${site_port}"
    echo " Configured Ports (WebTier)"
    echo "  Apache: ${httpd_port}"
    echo "  Tomcat: ${tomcat_port}"
    echo " Other choices"
    echo "  FDO: ${fdo_provider_choice}"
    echo "  CS-Map: ${csmap_choice}"
    echo "  Server IP: ${server_ip}"
    echo "********************************************"
}

dialog_welcome()
{
    $DIALOG --backtitle "$INSTALLER_TITLE" \
            --title "Welcome" --clear \
            --yesno "Welcome to the MapGuide Open Source Ubuntu installer. Would you like to proceed?" 10 30

    case $? in
      1)
        echo "Cancelled"
        exit 1;;
      255)
        echo "Cancelled"
        exit 255;;
    esac
}

dialog_fdo_provider()
{
    tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
    trap "rm -f $tempfile" 0 1 2 5 15

    #arcsde    	"OSGeo FDO Provider for ArcSDE" off \
    # Disable RDBMS provider selection by default
    $DIALOG --backtitle "$INSTALLER_TITLE" \
            --title "FDO Providers" --clear \
            --checklist "Check the FDO Providers you want to install" 20 61 5 \
            sdf  		"OSGeo FDO Provider for SDF" ON \
            shp    		"OSGeo FDO Provider for SHP" ON \
            sqlite 		"OSGeo FDO Provider for SQLite" ON \
            gdal    	"OSGeo FDO Provider for GDAL" ON \
            ogr    		"OSGeo FDO Provider for OGR" ON \
            kingoracle  "OSGeo FDO Provider for Oracle" off \
            rdbms	    "RDBMS FDO Providers (ODBC, MySQL, PostgreSQL)" off \
            wfs    		"OSGeo FDO Provider for WFS" ON \
            wms   		"OSGeo FDO Provider for WMS" ON  2> $tempfile

    fdo_provider_choice=`cat $tempfile | sed s/\"//g`
    case $? in
      1)
        echo "Cancelled"
        exit 1;;
      255)
        echo "Cancelled"
        exit 255;;
    esac
}

dialog_server()
{
    dialog --backtitle "$INSTALLER_TITLE" --title "Server Configuration" \
            --form "\nSet the port numbers that the MapGuide Server will listen on" 25 60 16 \
            "Server IP:"   1 1 "${DEFAULT_SERVER_IP}"   1 25 25 30 \
            "Admin Port:"  2 1 "${DEFAULT_ADMIN_PORT}"  2 25 25 30 \
            "Client Port:" 3 1 "${DEFAULT_CLIENT_PORT}" 3 25 25 30 \
            "Site Port:"   4 1 "${DEFAULT_SITE_PORT}"   4 25 25 30 2>/tmp/form.$$
    case $? in
      1)
        echo "Cancelled"
        exit 1;;
      255)
        echo "Cancelled"
        exit 255;;
    esac
    set_server_vars "/tmp/form.$$"
    rm /tmp/form.$$
}

dialog_webtier()
{
    dialog --backtitle "$INSTALLER_TITLE" --title "Web Tier Configuration" \
            --form "\nSet the port numbers that Apache/Tomcat will listen on" 25 60 16 \
            "Connect to Server IP:" 1 1 "${DEFAULT_SERVER_IP}"   1 25 25 30 \
            "Apache Port:"          2 1 "${DEFAULT_HTTPD_PORT}"  2 25 25 30 \
            "Tomcat Port:"          3 1 "${DEFAULT_TOMCAT_PORT}" 3 25 25 30 2>/tmp/form.$$
    case $? in
      1)
        echo "Cancelled"
        exit 1;;
      255)
        echo "Cancelled"
        exit 255;;
    esac
    set_webtier_vars "/tmp/form.$$"
    rm /tmp/form.$$
}

dialog_coordsys()
{
    tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
    trap "rm -f $tempfile" 0 1 2 5 15

    dialog --backtitle "$INSTALLER_TITLE" \
            --title "Coordinate System Configuration" --clear \
            --radiolist "Choose the CS-Map profile you want for this MapGuide Installation" 20 80 5 \
            "full" "Download/Install the full set of data files" ON \
            "lite" "Download/Install the lite configuration (no grid files)" off  2> $tempfile
    csmap_choice=`cat $tempfile`
    case $? in
      1)
        echo "Cancelled"
        exit 1;;
      255)
        echo "Cancelled"
        exit 255;;
    esac
}

install_fdo()
{
    # set initial registration state
    arcsde_registered=0
    gdal_registered=0
    kingoracle_registered=0
    rdbms_registered=0
    ogr_registered=0
    sdf_registered=0
    shp_registered=0
    sqlite_registered=0
    wfs_registered=0
    wms_registered=0

    # Include core and rdbms packages regardless of choice.
    fdo_provider_choice="core rdbms $fdo_provider_choice"
    # Download and install Ubuntu packages for FDO
    for file in $fdo_provider_choice
    do
        #echo "Downloading ${URL}/fdo-${file}_${FDOVER}.deb"
        wget -N ${URL}/fdo-${file}_${FDOVER}.deb
        #echo "Installing fdo-${file}_${FDOVER}.deb"
        dpkg -E -G --install fdo-${file}_${FDOVER}.deb
    done

    # Nuke the old providers.xml, we're rebuiding it
    providersxml=/usr/local/fdo-${FDOVER_MAJOR_MINOR_REV}/lib/providers.xml
    echo -ne "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?>" > ${providersxml}
    echo -ne "\n<FeatureProviderRegistry>" >> ${providersxml}
    for file in $fdo_provider_choice
    do
        case $file in
          arcsde)
            if [ $arcsde_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering ArcSDE Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.ArcSDE.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for ArcSDE</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to an ESRI ArcSDE-based data store, using Oracle and SQL Server</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libArcSDEProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            arcsde_registered=1
            ;;
          gdal)
            if [ $gdal_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering GDAL Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.Gdal.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for GDAL</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>FDO Provider for GDAL</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libGRFPProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            gdal_registered=1
            ;;
          kingoracle)
            if [ $kingoracle_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering King Oracle Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.KingOracle.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for Oracle</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to spatial and attribute data in Oracle Spatial</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libKingOracleProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            kingoracle_registered=1
            ;;
          rdbms)
            if [ $rdbms_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering ODBC Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.ODBC.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for ODBC</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>FDO Provider for ODBC</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libFdoODBC.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            echo "Registering PostgreSQL Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.PostgreSQL.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for PostgreSQL</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to PostgreSQL/PostGIS-based data store. Supports spatial data types and spatial query operations</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libFdoPostgreSQL.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            echo "Registering MySQL Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.MySQL.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for MySQL</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>FDO Provider for MySQL</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libFdoMySQL.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            rdbms_registered=1
            ;;
          ogr)
            if [ $ogr_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering OGR Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.OGR.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for OGR</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>FDO Access to OGR Data Sources</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libOGRProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            ogr_registered=1
            ;;
          sdf)
            if [ $sdf_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering SDF Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.SDF.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for SDF</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to Autodesk's spatial database format, a file-based geodatabase that supports multiple features/attributes, spatial indexing and file-locking</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libSDFProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            sdf_registered=1
            ;;
          shp)
            if [ $shp_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering SHP Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.SHP.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for SHP</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to spatial and attribute data in an ESRI SHP file</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libSHPProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            shp_registered=1
            ;;
          sqlite)
            if [ $sqlite_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering SQLite Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.SQLite.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for SQLite</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read/write access to feature data in a SQLite file</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libSQLiteProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            sqlite_registered=1
            ;;
          wfs)
            if [ $wfs_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering WFS Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.WFS.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for WFS</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read access to OGC WFS-based data store</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libWFSProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            wfs_registered=1
            ;;
          wms)
            if [ $wms_registered -eq 1 ];
            then
                continue
            fi
            echo "Registering WMS Provider"
            echo -ne "\n  <FeatureProvider>" >> ${providersxml}
            echo -ne "\n    <Name>OSGeo.WMS.${FDOVER_MAJOR_MINOR}</Name>" >> ${providersxml}
            echo -ne "\n    <DisplayName>OSGeo FDO Provider for WMS</DisplayName>" >> ${providersxml}
            echo -ne "\n    <Description>Read access to OGC WMS-based data store</Description>" >> ${providersxml}
            echo -ne "\n    <IsManaged>False</IsManaged>" >> ${providersxml}
            echo -ne "\n    <Version>${FDOVER_MAJOR_MINOR_REV}.0</Version>" >> ${providersxml}
            echo -ne "\n    <FeatureDataObjectsVersion>${FDOVER_MAJOR_MINOR_REV}.0</FeatureDataObjectsVersion>" >> ${providersxml}
            echo -ne "\n    <LibraryPath>libWMSProvider.so</LibraryPath>" >> ${providersxml}
            echo -ne "\n  </FeatureProvider>" >> ${providersxml}
            wms_registered=1
            ;;
        esac
    done
    echo -ne "\n</FeatureProviderRegistry>" >> ${providersxml}
}

install_mapguide_packages()
{
    # Download Ubuntu packages for MapGuide
    mapguide_packages="platformbase coordsys common server webextensions httpd"
    if [ $csmap_choice = "lite" ]; then
        mapguide_packages="platformbase coordsys-lite common server webextensions httpd"
    fi
    for file in $mapguide_packages
    do
        echo "[download]: ${URL}/mapguideopensource-${file}_${MGVER}.deb"
        wget -N ${URL}/mapguideopensource-${file}_${MGVER}.deb
        echo "[install]: mapguideopensource-${file}_${MGVER}.deb"
        dpkg -E -G --install mapguideopensource-${file}_${MGVER}.deb
    done
}

post_install()
{
    echo "[config]: Updating serverconfig.ini with configuration choices"
    sed -i 's/MachineIp.*= '"${DEFAULT_SERVER_IP}"'/MachineIp = '"${server_ip}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin/serverconfig.ini
    sed -i 's/IpAddress.*= '"${DEFAULT_SERVER_IP}"'/IpAddress = '"${server_ip}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin/serverconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_ADMIN_PORT}"'/Port = '"${admin_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin/serverconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_CLIENT_PORT}"'/Port = '"${client_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin/serverconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_SITE_PORT}"'/Port = '"${site_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin/serverconfig.ini
    echo "[config]: Updating webconfig.ini with configuration choices"
    sed -i 's/IpAddress.*= '"${DEFAULT_SERVER_IP}"'/IpAddress = '"${webtier_server_ip}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/www/webconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_ADMIN_PORT}"'/Port = '"${admin_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/www/webconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_CLIENT_PORT}"'/Port = '"${client_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/www/webconfig.ini
    sed -i 's/Port.*= '"${DEFAULT_SITE_PORT}"'/Port = '"${site_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/www/webconfig.ini
    echo "[config]: Updating httpd.conf with configuration choices"
    sed -i 's/Listen '"${DEFAULT_HTTPD_PORT}"'/Listen '"${httpd_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/apache2/conf/httpd.conf
    sed -i 's/worker.worker1.port='"${DEFAULT_TOMCAT_PORT}"'/worker.worker1.port='"${tomcat_port}"'/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/apache2/conf/workers.properties
    sed -i 's/Connector port=\"'"${DEFAULT_TOMCAT_PORT}"'\"/Connector port=\"'"${tomcat_port}"'\"/g' /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/tomcat/conf/server.xml
    echo "[config]: Updating tomcat configs with configuration choices"

    echo "[config]: Fixing permissions for certain folders"
    chmod 777 /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/www/TempDir

}

# Create temporary download directory
mkdir -p ${TEMPDIR}
pushd ${TEMPDIR}
main
popd
rm -rf ${TEMPDIR}