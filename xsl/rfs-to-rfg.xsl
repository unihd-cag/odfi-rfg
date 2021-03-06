<?xml version="1.0" encoding="UTF-8"?>
<!--
## RFG Register File Generator
## Copyright (C) 2014  University of Heidelberg - Computer Architecture Group
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:docbook="http://docbook.org/ns/docbook"
    xmlns="http://www.w3.org/1999/xhtml">
 

    <!-- Text Output -->
    <xsl:output
        method="text"
        />
    
    <xsl:param name="tab"><xsl:text>    </xsl:text></xsl:param>

    <!--Top :Regfile or Regroot -->
    <!-- ####################### -->
    <xsl:template match="/regfile">
osys::rfg::registerFile <xsl:value-of select="./regroot/@name"/> {
    
<xsl:apply-templates select="./regroot/*"/>
}

    </xsl:template>

    <xsl:template match="/regroot">

registerFile <xsl:value-of select="@name"/> {
    
<xsl:apply-templates>
</xsl:apply-templates>

}

    </xsl:template>


    <!-- Regroot -> Groups -->
    <!-- ################## -->
    <xsl:template match="regroot">

    <!-- Gather depth -->
    <xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
    <xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
        
<xsl:value-of select="$hier-level-tab"/> group <xsl:value-of select="@name"/> {

<!-- Absolute Address --> 
<xsl:if test="@_absoluteAddress">
<xsl:value-of select="$hier-level-tab"/>    setAbsoluteAddressFromHex <xsl:value-of select="@_absoluteAddress"/>
<xsl:text>
    
</xsl:text>   
</xsl:if>


<xsl:apply-templates/>

<xsl:value-of select="$hier-level-tab"/> }

    </xsl:template>
    <!-- ########################## -->
    <!-- ramblock --> 
    <!-- ########################## -->
    <xsl:template match="ramblock">

    <xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|ramblock|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
    <xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
    <xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>

<xsl:value-of select="$hier-level-tab"/>ramBlock <xsl:value-of select="@name"/> {
        <!-- Description -->
<xsl:if test="@desc">
    <xsl:value-of select="$hier-level-tab-more"/>description "<xsl:value-of select="fn:replace(@desc,'\[','\\[')"/>"
</xsl:if>

<!-- Absolute Address --> 
<xsl:if test="@_absoluteAddress">
<xsl:value-of select="$hier-level-tab"/>    setAbsoluteAddressFromHex <xsl:value-of select="@_absoluteAddress"/>
<xsl:text>
    
</xsl:text>   
</xsl:if>

<!-- width --> 
<xsl:if test="@ramwidth">
<xsl:value-of select="$hier-level-tab"/>    width <xsl:value-of select="@ramwidth"/>
<xsl:text>
    
</xsl:text>   
</xsl:if>

<!-- depth --> 
<xsl:if test="@addrsize">
<xsl:value-of select="$hier-level-tab"/>    depth [expr int(pow(2,<xsl:value-of select="@addrsize"/>))]
<xsl:text>
    
</xsl:text>   
</xsl:if>

    <!-- Rights and attributes--> 
    <xsl:value-of select="$hier-level-tab-more"/>software {
    <xsl:value-of select="$hier-level-tab-more"/>       <xsl:value-of select="@sw"/>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@addr_shift">
        <xsl:value-of select="$hier-level-tab-more"/>   address_shift <xsl:value-of select="@addr_shift"/>
    </xsl:if>
    <xsl:text>
    </xsl:text>  
<xsl:value-of select="$hier-level-tab-more"/>}    

<xsl:text>  
</xsl:text>

    <xsl:value-of select="$hier-level-tab-more"/>hardware {

    <xsl:value-of select="$hier-level-tab-more"/> <xsl:value-of select="@hw"/>
    <xsl:text>
</xsl:text>
<xsl:if test="@shared_bus='1'">
    <xsl:value-of select="$hier-level-tab-more"/>   shared_bus 
</xsl:if>
    <xsl:text>
    </xsl:text> 
    <!-- Special Attributes -->
    <!-- ################### -->
    <xsl:if test="@counter">
        <xsl:value-of select="$hier-level-tab-more"/>   counter
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@te">
        <xsl:value-of select="$hier-level-tab-more"/>   trigger "<xsl:value-of select="@te"/>"
    </xsl:if>
    <xsl:text>
    </xsl:text>  
    <xsl:if test="@counter='2'">
        <xsl:value-of select="$hier-level-tab-more"/>   edge_trigger
    </xsl:if>
    <xsl:text>
    </xsl:text>  
    <xsl:if test="@rreinit">
        <xsl:value-of select="$hier-level-tab-more"/>   rreinit
    </xsl:if>
    <xsl:text>
    </xsl:text>  
    <xsl:if test="@sw_written='1'">
        <xsl:value-of select="$hier-level-tab-more"/>   software_written
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@sw_written='2'">
        <xsl:value-of select="$hier-level-tab-more"/>   changed
    </xsl:if>
    <xsl:text>
    </xsl:text> 
    <xsl:if test="not(@hw_wen) and not(@counter)">
        <xsl:value-of select="$hier-level-tab-more"/>   no_wen
    </xsl:if>
    <xsl:text>
    </xsl:text> 
    <xsl:if test="@external">
        <xsl:value-of select="$hier-level-tab-more"/>   external
    </xsl:if>     
    <xsl:text>
    </xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/>}
    }

<xsl:apply-templates />
</xsl:template>

   <!-- ########################## -->
    <!-- rrinst --> 
    <!-- ########################## -->
    <xsl:template match="rrinst">
    <xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|rrinst|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
    <xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
    <xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>
    <xsl:if test="@external">
    <xsl:choose>
    <xsl:when test="@external='1'">    external <xsl:value-of select="fn:replace(@file,'.xml','.rf')"> </xsl:value-of><xsl:text> </xsl:text><xsl:value-of select="@name"></xsl:value-of></xsl:when>
    <xsl:when test="@external='0'">    internal <xsl:value-of select="fn:replace(@file,'.xml','.rf')"> </xsl:value-of><xsl:text> </xsl:text><xsl:value-of select="@name"></xsl:value-of></xsl:when>
        </xsl:choose>
    </xsl:if>

    <xsl:if test= "not(@external)">
    internal <xsl:value-of select="fn:replace(@file,'.xml','.rf')"></xsl:value-of><xsl:text> </xsl:text><xsl:value-of select="@name"></xsl:value-of>
    </xsl:if>
<xsl:text>
</xsl:text>

<xsl:apply-templates />
</xsl:template>
    <!-- ########################## -->
    <!-- Reg64 --> 
    <!-- ########################## -->
    <xsl:template match="reg64">

    <!-- In Repeat ? --> 
    <xsl:param name="isRepeat" select="false()"/>

    <xsl:variable name="name">
        <xsl:choose>
            <xsl:when  test="$isRepeat"><xsl:value-of select="@name"/>_$i</xsl:when>
            <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Gather depth -->
    <xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
    <xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
    <xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>

<xsl:value-of select="$hier-level-tab"/>register <xsl:value-of select="$name"/> {

<!-- Description -->
<xsl:if test="@desc">
    <xsl:value-of select="$hier-level-tab-more"/>description "<xsl:value-of select="fn:replace(@desc,'\[','\\[')"/>"
</xsl:if>

<!-- Absolute Address --> 
<xsl:if test="@_absoluteAddress">
<xsl:value-of select="$hier-level-tab"/>    setAbsoluteAddressFromHex <xsl:value-of select="@_absoluteAddress"/>
<xsl:text>
    
</xsl:text>   
</xsl:if>

<!-- Special Attributes -->
<!-- ################### -->
<xsl:if test="./rreinit">
<xsl:value-of select="$hier-level-tab"/>    hardware {
    
    <xsl:value-of select="$hier-level-tab"/>    rreinit_source    

}
</xsl:if>



<xsl:apply-templates />

<xsl:value-of select="$hier-level-tab"/>}


</xsl:template>
    <!-- ########################## -->
    <!-- Aligner --> 
    <!-- ########################## -->
    <xsl:template match="aligner">
    <!-- Gather depth -->
    <xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
    <xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
    <xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>

    <xsl:value-of select="$hier-level-tab"/>aligner <xsl:value-of select="@to"/>
    <xsl:text>
    
    </xsl:text> 
<xsl:apply-templates />
</xsl:template>
    <!-- Fields -->
    <!-- ################## -->
    <xsl:template match="hwreg">


<!-- Name -->
<xsl:variable name="name">
    <xsl:choose>
        <xsl:when  test="@name"><xsl:value-of select="@name"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="../@name"/></xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Gather depth -->
<xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
<xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
<xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>
       
<xsl:value-of select="$hier-level-tab"/>field <xsl:value-of select="$name"/> {

<!-- Description -->
<xsl:if test="@desc">
    <xsl:value-of select="$hier-level-tab-more"/>description "<xsl:value-of select="fn:replace(@desc,'\[','\\[')"/>"
</xsl:if>
   

    <!-- Width -->
    <xsl:value-of select="$hier-level-tab-more"/><xsl:choose>
        <xsl:when test="fn:matches(@width,'^[A-Z_]+')">width        $<xsl:value-of select="@width"/></xsl:when>
        <xsl:otherwise>width        <xsl:value-of select="@width"/></xsl:otherwise>
    </xsl:choose>
    <!-- Reset -->
    <xsl:text>
    </xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/><xsl:choose>
        <xsl:when test="fn:matches(@reset,'^[A-Z_]+')">reset        $<xsl:value-of select="@reset"/></xsl:when>
        <xsl:otherwise>reset        <xsl:value-of select="@reset"/></xsl:otherwise>
    </xsl:choose>
    <xsl:text>
    </xsl:text>
    <!-- Rights and attributes--> 
    <xsl:value-of select="$hier-level-tab-more"/>software {
    <xsl:value-of select="$hier-level-tab-more"/>       <xsl:value-of select="@sw"/>
    <xsl:text>
    </xsl:text>
<!-- Special Attributes -->
    <!-- ################### -->
    <xsl:if test="@sw_write_clr">
    <xsl:value-of select="$hier-level-tab-more"/>   write_clear
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@sw_write_xor">
    <xsl:value-of select="$hier-level-tab-more"/>   write_xor
    </xsl:if> 
    <xsl:text>
    </xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/>}    
    <xsl:text>
    </xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/>hardware {
    <xsl:value-of select="$hier-level-tab-more"/> <xsl:value-of select="@hw"/>
    <!-- Special Attributes -->
    <!-- ################### -->
    <xsl:text>
    </xsl:text>
    <xsl:if test="@counter">
    <xsl:value-of select="$hier-level-tab-more"/>   counter
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@counter='2'">
    <xsl:value-of select="$hier-level-tab-more"/>   edge_trigger
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@rreinit">
    <xsl:value-of select="$hier-level-tab-more"/>   rreinit
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@sw_written='1'">
    <xsl:value-of select="$hier-level-tab-more"/>   software_written
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="@te">
        <xsl:value-of select="$hier-level-tab-more"/>   trigger "<xsl:value-of select="@te"/>"
    </xsl:if>
    <xsl:text>
    </xsl:text>  
    <xsl:if test="@sw_written='2'">
    <xsl:value-of select="$hier-level-tab-more"/>   changed
    </xsl:if>
    <xsl:text>
    </xsl:text>
    <xsl:if test="not(@hw_wen) and not(@counter)">
    <xsl:value-of select="$hier-level-tab-more"/>   no_wen
    </xsl:if>    
    <xsl:text>
    </xsl:text>
    <xsl:if test="@hw_clr">
    <xsl:value-of select="$hier-level-tab-more"/>   clear
    </xsl:if> 
    <xsl:text>
    </xsl:text>
    <xsl:if test="@sticky">
    <xsl:value-of select="$hier-level-tab-more"/>   sticky
    </xsl:if>
    <xsl:text>
    </xsl:text>
<xsl:value-of select="$hier-level-tab-more"/>}
    <xsl:text>
    </xsl:text>
<xsl:value-of select="$hier-level-tab"/>}
    <xsl:text>
    </xsl:text>
</xsl:template>
    <!-- ################## -->
    <!-- Reserved           -->
    <!-- ################## -->
    <xsl:template match="reserved">
    <!-- Gather depth -->
<xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg" level="multiple" format="1"></xsl:number></xsl:variable>
<xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
<xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>
<xsl:value-of select="$hier-level-tab-more"/>reserved <xsl:choose>
        <xsl:when test="fn:matches(@width,'^[A-Z_]+')">$<xsl:value-of select="@width"/> </xsl:when>
        <xsl:otherwise> <xsl:value-of select="@width"/></xsl:otherwise>
</xsl:choose>
<xsl:text>
</xsl:text>
</xsl:template>
    <!-- ################## -->
    <!-- attributes --> 
    <!-- ################## -->
    <template match="@_absoluteAddress">absoluteAddress <xsl:value-of select="."/>
        
    </template>
    
    <!-- ################## -->
    <!-- Repeat --> 
    <!-- ################## -->
    <xsl:template match="repeat">

<!-- Gather depth -->
<xsl:variable name="hier-pos"><xsl:number from="regroot" count="regroot|reg64|hwreg|repeat" level="multiple" format="1"></xsl:number></xsl:variable>
<xsl:variable name="hier-level-tab"><xsl:value-of select="fn:replace(fn:replace($hier-pos,'[0-9]',$tab),'\.','')"></xsl:value-of></xsl:variable>
<xsl:variable name="hier-level-tab-more"><xsl:value-of select="$hier-level-tab"></xsl:value-of><xsl:text>    </xsl:text></xsl:variable>

::repeat <xsl:value-of select="@loop"/> {
    
    <xsl:apply-templates>
        <xsl:with-param name="isRepeat" select="true()"/>
    </xsl:apply-templates>

}

    </xsl:template>

    <!-- ################## -->
    <!-- IF Defs -->
    <!-- ################## -->

    <!-- #ifdef -->
    <xsl:template name="ifdef" match="*/text()[fn:starts-with(fn:normalize-space(),'#ifdef ')]">
        <!-- Search variable name-->
    <xsl:if test="fn:matches(fn:normalize-space(),'#ifdef ')">
        <xsl:variable name="var"><xsl:value-of select="fn:replace(fn:normalize-space(),'#ifdef ','')"/></xsl:variable>
        if {[info exists <xsl:value-of select="$var"/>]} {
    </xsl:if>
</xsl:template>
    <!-- ifndef -->
    <xsl:template match="*/text()[fn:starts-with(fn:normalize-space(),'#ifndef ')]">
        <!-- Search variable name-->
    <xsl:if test="fn:matches(fn:normalize-space(),'#ifndef ')">
        <xsl:variable name="var"><xsl:value-of select="fn:replace(fn:normalize-space(),'#ifndef ','')"/></xsl:variable>
        if {![info exists <xsl:value-of select="$var"/>]} {
    </xsl:if>
</xsl:template>    
    <!-- #else -->
    <xsl:template match="*/text()[fn:starts-with(fn:normalize-space(),'#else')]">

       } else {

</xsl:template>

    <!-- #endif -->
    <xsl:template match="*/text()[fn:starts-with(fn:normalize-space(),'#endif')]">

       }

       <xsl:call-template name="ifdef"/>
</xsl:template>



    <!-- Ignores --> 
    <!-- ######## -->
    <xsl:template match="node()"></xsl:template>
</xsl:stylesheet>
