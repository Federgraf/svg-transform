<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
	xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
	xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:f="http://www.lionel.org/functions"
	xpath-default-namespace="http://www.w3.org/2000/svg" exclude-result-prefixes="xs xsl f">

	<xsl:strip-space elements="*"/>


	<xsl:mode name="copy" on-no-match="deep-copy"/>

	<xsl:param name="inkscape-default-resolution" as="xs:string"
		select="
			if (//@inkscape:version[contains(., '0.92')]) then
				('96')
			else
				'90'"/>

	<xsl:output method="xml" indent="yes"/>

	<xsl:function name="f:convertUnit" as="xs:decimal">
		<xsl:param name="in-value" as="xs:decimal"/>
		<xsl:param name="in-unit" as="xs:string"/>
		<xsl:param name="out-unit" as="xs:string"/>
		<xsl:param name="reso" as="xs:string"/>
		<xsl:variable name="mmToPx" select="xs:decimal($reso) div 25.4" as="xs:decimal"/>
		<xsl:choose>
			<xsl:when test="$in-unit = 'mm' and $out-unit = 'px'">
				<xsl:value-of select="$in-value * $mmToPx"/>
			</xsl:when>

			<xsl:when test="$in-unit = 'px' and $out-unit = 'mm'">
				<xsl:value-of select="$in-value div $mmToPx"/>
			</xsl:when>

			<xsl:when test="$in-unit = 'mm' and $out-unit = 'cm'">
				<xsl:value-of select="$in-value div 10"/>
			</xsl:when>

			<xsl:when test="$in-unit = 'cm' and $out-unit = 'mm'">
				<xsl:value-of select="$in-value * 10"/>
			</xsl:when>

			<xsl:when test="$in-unit = 'cm' and $out-unit = 'px'">
				<xsl:value-of select="$in-value * 10 * $mmToPx"/>
			</xsl:when>

			<xsl:when test="$in-unit = 'px' and $out-unit = 'cm'">
				<xsl:value-of select="$in-value div $mmToPx div 10"/>
			</xsl:when>

		</xsl:choose>
	</xsl:function>



	<xsl:variable name="links-to-marker" as="xs:string*">
		<!--    does not parse marker styles since they do not point to markers    -->

		<!-- find references to markers in style attribute -->
		<xsl:variable name="marker_in_style" as="item()*"
			select="//*[not(ancestor-or-self::marker)]/tokenize(@style, ';')[contains(., 'marker-')]"/>

		<!-- find references to markers in marker-end or marker-start attributes
        this is to remain compatible with files that have been cleaned by a previous version of the cleaner that separated the style attribute -->
		<xsl:variable name="marker_in_att" as="item()*"
			select="//*[not(ancestor-or-self::marker)]/@*[contains(name(), 'marker-')]"/>

		<xsl:for-each select="$marker_in_style, $marker_in_att">
			<xsl:sequence select="substring-after(substring-before(., ')'), '#')"/>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="links-to-gradient" as="xs:string*">
		<!--    does not parse gradient styles since they do not point to gradients    -->

		<!-- find references to gradients in fill attributes only -->
		<xsl:variable name="gradient_in_style" as="item()*"
		    select="substring-after(substring-before(//*[not(ancestor-or-self::linearGradient)]/tokenize(@style, ';')[contains(., 'Gradient') and contains(., 'fill')], ')'), '#')"/>

		<!-- find references to gradients in fill attributes only
        this is to remain compatible with files that have been cleaned by a previous version of the cleaner that separated the style attribute -->
		<xsl:variable name="gradient_in_att" as="item()*"
		    select="substring-after(substring-before(//*[not(ancestor-or-self::linearGradient)]/@*[contains(name(), 'fill') and contains(., 'Gradient')], ')'), '#')"/>
	    
	    <xsl:variable name="gradient_in_other_gradient" as="item()*" 
	        select="substring-after(//*[contains(local-name(),'Gradient')]/@xlink:href[contains(.,'Gradient')], '#')"/>

	    <xsl:for-each select="$gradient_in_style, $gradient_in_att, $gradient_in_other_gradient">
			<xsl:sequence select="."/>
		</xsl:for-each>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="svg">
				<xsl:apply-templates select="svg"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="*" mode="copy"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="svg">
		<!-- for debug -->
		<!-- <xsl:message select="$links-to-marker"></xsl:message> -->
		<svg xmlns="http://www.w3.org/2000/svg">
			<xsl:call-template name="svg-namespaces"/>
			<xsl:if test="not(@viewBox)">
				<xsl:call-template name="create_viewBox"/>
			</xsl:if>
			<xsl:apply-templates select="@* | *"/>
		</svg>
	</xsl:template>

	<xsl:template match="flowRoot"/>

	<xsl:template match="@* | node()">
		<xsl:copy copy-namespaces="no">
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template
		match="*[namespace-uri() != 'http://www.w3.org/2000/svg' and namespace-uri() != 'http://www.w3.org/1999/xlink'] | @*[contains(name(), ':') and not(starts-with(name(), 'xlink:')) and not(starts-with(name(), 'xml:')) and not(starts-with(name(), 'sodipodi:role')) and not(starts-with(name(), 'inkscape:version'))] | *[local-name() = 'script']"/>


	<xsl:template match="text[not(normalize-space(.))]"/>
    
    <!-- remove Illustrator styles -->
    <xsl:template match="style"/>
    <xsl:template match="@class"/>
	
	<!-- remove empty paths -->
	<xsl:template match="path[@d[not(normalize-space(.))]]"/>


	<!-- remove unused markers -->
	<xsl:template match="marker[not(@id = $links-to-marker)]"/>
	
	<!-- remove unused gradients -->

	<xsl:template match="linearGradient[not(@id = $links-to-gradient)]"/>

	<xsl:template match="radialGradient[not(@id = $links-to-gradient)]"/>

	<xsl:template match="@style">
		<xsl:variable name="style-list" select="tokenize(., ';')" as="item()*"/>
		<xsl:variable name="style-list-improved" as="item()*">
			<xsl:for-each select="$style-list">
				<xsl:choose>
					<!-- strokes should never be made with gradients, nor should they be "composer blue" -->
					<xsl:when test="starts-with(., 'stroke:url') or contains(.,'stroke:#000020')">
							<xsl:copy-of select="'stroke:#000000'"/>						
					</xsl:when>
					<xsl:when test="starts-with(., '-inkscape-')"/>
					<xsl:otherwise>
							<xsl:copy-of select="."/>						
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:attribute name="style">
			<xsl:value-of select="$style-list-improved" separator=";"/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="tspan">
		<xsl:copy copy-namespaces="no">
			<xsl:if test="not(@sodipodi:role)">
				<xsl:attribute name="role"
					namespace="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
					>line</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template name="svg-namespaces">
		<xsl:namespace name="sodipodi" select="'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd'"/>
		<xsl:namespace name="inkscape" select="'http://www.inkscape.org/namespaces/inkscape'"/>
		<xsl:if test="//*[@xlink:*]">
			<xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="create_viewBox">

		<xsl:variable name="width-px">
			<xsl:apply-templates select="@width" mode="calculate-dim"/>
		</xsl:variable>
		<xsl:variable name="height-px">
			<xsl:apply-templates select="@height" mode="calculate-dim"/>
		</xsl:variable>

		<xsl:attribute name="viewBox">
			<xsl:text>0 0 </xsl:text>
			<xsl:value-of select="$width-px"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="$height-px"/>
		</xsl:attribute>

	</xsl:template>


	<xsl:template match="@width | @height" mode="calculate-dim">
		<xsl:choose>
			<xsl:when test=". castable as xs:decimal">
				<xsl:value-of select="."/>
			</xsl:when>
			<xsl:when test="contains(., 'px')">
				<xsl:value-of select="substring-before(., 'px')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="unit" select="substring(., string-length(.) - 1, 2)"/>
				<xsl:value-of
					select="f:convertUnit(xs:decimal(substring-before(., $unit)), $unit, 'px', $inkscape-default-resolution)"
				/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
