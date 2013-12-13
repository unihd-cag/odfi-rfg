<?xml version="1.0" encoding="UTF-8"?>
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

    <xsl:template match="/regroot">#!/usr/bin/env rfg

osys::rfg::registerFile <xsl:value-of select="@name"/> {
    
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


    <!-- Reg64 --> 
    <!-- ##### -->
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

<xsl:value-of select="$hier-level-tab"/>register <xsl:value-of select="$name"/> {

<!-- Absolute Address --> 
<xsl:if test="@_absoluteAddress">
<xsl:value-of select="$hier-level-tab"/>    setAbsoluteAddressFromHex <xsl:value-of select="@_absoluteAddress"/>
<xsl:text>
    
</xsl:text>   
</xsl:if>

<xsl:apply-templates />

<xsl:value-of select="$hier-level-tab"/>}


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
    <xsl:value-of select="$hier-level-tab-more"/>width        <xsl:value-of select="@width"/> 
<xsl:text>
</xsl:text>
    
    <!-- Reset -->
    <xsl:value-of select="$hier-level-tab-more"/><xsl:choose>
        <xsl:when test="fn:matches(@reset,'^[A-Z_]+')">reset        $<xsl:value-of select="@reset"/></xsl:when>
        <xsl:otherwise>reset        <xsl:value-of select="@reset"/></xsl:otherwise>
    </xsl:choose>
    
<xsl:text>
</xsl:text>

    <!-- Rights and attributes--> 
    <xsl:value-of select="$hier-level-tab-more"/>attributes software {
    <xsl:value-of select="$hier-level-tab-more"/>       <xsl:value-of select="@sw"/>
    <xsl:text>
</xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/>}    

<xsl:text>  
</xsl:text>

    <xsl:value-of select="$hier-level-tab-more"/>attributes hardware {

    <xsl:value-of select="$hier-level-tab-more"/> <xsl:value-of select="@hw"/>
    <xsl:text>
</xsl:text>
    
    <!-- Special Attributes -->
    <!-- ################### -->
    <xsl:if test="@counter">
        <xsl:value-of select="$hier-level-tab-more"/>    counter
    </xsl:if>
    <xsl:if test="@rreinit">
        <xsl:value-of select="$hier-level-tab-more"/>    rreinit
    </xsl:if>
    

    <xsl:text>
</xsl:text>
    <xsl:value-of select="$hier-level-tab-more"/>}

<xsl:text>
</xsl:text>

<xsl:value-of select="$hier-level-tab"/>}

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
    <xsl:template match="text()[fn:starts-with(fn:normalize-space(),'#ifdef ')]">

        <!-- Search variable name-->
        <xsl:variable name="var"><xsl:value-of select="fn:replace(fn:normalize-space(),'#ifdef ','')"/></xsl:variable>
        if {[info exists <xsl:value-of select="$var"/>]} {

</xsl:template>
    
    <!-- #else -->
    <xsl:template match="text()[fn:starts-with(fn:normalize-space(),'#else')]">

       } else {


</xsl:template>

    <!-- #endif -->
    <xsl:template match="text()[fn:starts-with(fn:normalize-space(),'#endif')]">

       }

</xsl:template>



    <!-- Ignores --> 
    <!-- ######## -->
    <xsl:template match="node()"></xsl:template>

 </xsl:stylesheet>
