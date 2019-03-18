<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    xmlns:f="http://www.lionel.org/functions"
    xpath-default-namespace="http://www.w3.org/2000/svg" exclude-result-prefixes="xs math xsl xd"
    version="3.0">
    <xsl:import href="clean_svg.xsl"/>
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="redim-text" as="xs:boolean" select="true()"/>
    
    <xsl:mode name="redim" on-no-match="shallow-copy"/>

   <!-- paramètres à définir par l'utilisateur -->
    <xsl:param name="dimension"/>
    <xsl:param name="value"/>
    <xsl:param name="unit"/>
    <xsl:param name="resolution" as="xs:string"/>
    <xsl:param name="enforce" as="xs:boolean"/>

    <!-- facteur de conversion inkscape mm to px-->
    <xsl:param name="mmToPx" select="xs:decimal($resolution) div 25.4" as="xs:decimal"/>

    <!-- dimension correspondant à celle choisie par l'utilisateur -->
    <xsl:variable name="matching_dimension" select="svg/@*[name() = $dimension]"/>

    <xd:doc>
        <xd:desc>define when the template must be used</xd:desc>
    </xd:doc>

    <xsl:template match="/">
        <xsl:if test="$redim-text = false() and //text">
            <xsl:message terminate="yes">
                <xsl:text>did not resize: </xsl:text>
                <xsl:value-of select="base-uri()"/>
            </xsl:message>
        </xsl:if>

        <xsl:variable name="cleaned">
            <xsl:apply-imports/>
        </xsl:variable>
        <xsl:apply-templates select="$cleaned" mode="redim"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>génère les attributs @height et @width</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="svg/@width | svg/@height" mode="redim">
        <!-- si la dimension contient des lettres, charger les deux derniers caractères dans la variable (px si vide)-->
        <xsl:variable name="original_unit">
            <xsl:choose>
                <xsl:when test="not(. castable as xs:decimal)">
                    <xsl:value-of select="substring(., string-length(.) - 1, 2)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'px'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- récupère la valeur de la dimension correspondant à celle choisie par l'utilisateur sans l'unité -->
        <xsl:variable name="matching_value" as="xs:decimal"
            select="
                if ($matching_dimension castable as xs:decimal) then
                    $matching_dimension
                else
                    xs:decimal(substring-before($matching_dimension, $original_unit))"/>


        <!-- récupère la valeur de la dimension actuelle sans l'unité -->
        <xsl:variable name="original_value"
            select="
                if (. castable as xs:decimal) then
                    .
                else
                    xs:decimal(substring-before(., $original_unit))"/>

        <xsl:variable name="factor">
            <xsl:choose>
                <xsl:when test="not($value)">
                    <xsl:value-of select="1"/>
                </xsl:when>
            	<xsl:when test="$unit = 'percentage'">
            		<xsl:value-of select="xs:decimal($value) div 100"/>
            	</xsl:when>
                <xsl:when test="$unit = $original_unit">
                    <xsl:value-of select="xs:decimal($value) div xs:decimal($matching_value)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="f:convertUnit(xs:decimal($value), $unit, $original_unit, $resolution) div xs:decimal($matching_value)"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:attribute name="{name()}">
            <xsl:choose>
                <xsl:when test="$enforce = true() and $unit != $original_unit and $unit!= 'percentage'">
                    <xsl:value-of
                        select="
                            concat(f:convertUnit(xs:decimal($original_value), $original_unit, $unit, $resolution) * $factor, if ($unit = 'px') then
                                ''
                            else
                                $unit)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="
                            concat((xs:decimal($original_value) * $factor), if ($original_unit = 'px') then
                                ''
                            else
                                $original_unit)"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>

    </xsl:template>
</xsl:stylesheet>
