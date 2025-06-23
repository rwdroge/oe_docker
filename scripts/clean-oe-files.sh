#!/bin/sh 

CONTAINERTYPE=$1

case "$CONTAINERTYPE" in
    PAS*)
        rm -rf /usr/dlc/*OpenEdge*
        rm -rf /usr/dlc/*sports*
        rm -f /usr/dlc/bin/*sql*
        rm -f /usr/dlc/bin/_mprosrv
        rm -f /usr/dlc/bin/_mproshut
        rm -f /usr/dlc/bin/dbtool
        # oe_oemgmt
        rm -rf /usr/oemgmt
        rm -rf /usr/wrk_oemgmt
        # dlc
        rm -rf /usr/dlc/gradle
        rm -rf /usr/dlc/src
        rm -rf /usr/dlc/templates
        rm -f  /usr/dlc/ade.pf
        rm -rf /usr/dlc/ant/manual
        rm -f  /usr/dlc/demo*
        rm -f  /usr/dlc/inst_hlp
        rm -rf /usr/dlc/java/ext/*
        rm -f  /usr/dlc/newk*
        rm -rf /usr/dlc/odbc
        rm -rf /usr/dlc/oebuild
        rm -rf /usr/dlc/perl
        rm -rf /usr/dlc/prohelp
        rm -rf /usr/dlc/prolang/ame
        rm -rf /usr/dlc/prolang/utf
        rm -f /usr/dlc/bin/xsdto4gl
        # other
        rm -rf /var/cache
        ;;
    DB)
        rm -rf /usr/dlc/ora
        rm -rf /usr/dlc/dotnet
        rm -rf /usr/dlc/sonic
        rm -rf /usr/dlc/esbadapter
        rm -f /usr/dlc/bin/*sts*
        rm -f /usr/dlc/bin/_bprowsdldoc
        rm -rf /usr/dlc/servers
        rm -rf /usr/dlc/ubqmanager
        # oe_oemgmt
        rm -rf /usr/oemgmt
        rm -rf /usr/wrk_oemgmt
        # dlc
        rm -rf /usr/dlc/gradle
        rm -rf /usr/dlc/src
        rm -rf /usr/dlc/templates
        rm -f  /usr/dlc/ade.pf
        rm -rf /usr/dlc/ant/manual
        rm -f  /usr/dlc/demo*
        rm -f  /usr/dlc/inst_hlp
        rm -rf /usr/dlc/java/ext/*
        rm -f  /usr/dlc/newk*
        rm -rf /usr/dlc/odbc
        rm -rf /usr/dlc/oebuild
        rm -rf /usr/dlc/perl
        rm -rf /usr/dlc/prohelp
        rm -rf /usr/dlc/prolang/ame
        rm -rf /usr/dlc/prolang/utf
        rm -f /usr/dlc/bin/xsdto4gl
        # other
        rm -rf /var/cache
        ;;
    COMPILER)
        # rm -rf /usr/dlc/*OpenEdge*
        rm -f /usr/dlc/bin/*sql*
        rm -f /usr/dlc/bin/_mprosrv
        rm -f /usr/dlc/bin/_mproshut
        rm -f /usr/dlc/bin/dbtool
        rm -rf /usr/dlc/servers
        # oe_oemgmt
        rm -rf /usr/oemgmt
        rm -rf /usr/wrk_oemgmt
        # dlc
        # not removing gradle for CI/CD purposes
        # rm -rf /usr/dlc/gradle
        # rm -rf /usr/dlc/src
        rm -rf /usr/dlc/templates
        rm -f  /usr/dlc/ade.pf
        rm -rf /usr/dlc/ant/manual
        rm -f  /usr/dlc/demo*
        rm -f  /usr/dlc/inst_hlp
        rm -rf /usr/dlc/java/ext/*
        rm -f  /usr/dlc/newk*
        rm -rf /usr/dlc/odbc
        rm -rf /usr/dlc/oebuild
        rm -rf /usr/dlc/perl
        rm -rf /usr/dlc/prohelp
        rm -rf /usr/dlc/prolang/ame
        rm -rf /usr/dlc/prolang/utf
        rm -f /usr/dlc/bin/xsdto4gl
        # other
        rm -rf /var/cache
        ;;
    
    *)  
        #Files that can be removed regardless of container type

        # oe_oemgmt
        echo "no match found for containertype"
        ;;
esac

        
