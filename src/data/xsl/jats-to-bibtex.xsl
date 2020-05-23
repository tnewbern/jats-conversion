<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:date="http://exslt.org/dates-and-times"
        extension-element-prefixs="date">
    <xsl:output method="text" encoding="utf-8"/>

    <xsl:variable name="month-abbreviations" select="'  janfebmaraprmayjunjulaugsepoctnovdec'"/>

    <xsl:template match="/">
        <xsl:apply-templates select="article/front/article-meta"/>
    </xsl:template>

    <xsl:template match="article-meta">
        <xsl:text>@article{</xsl:text>
        <xsl:value-of select="concat('PMC', article-id[@pub-id-type='pmc'])"/>
        <xsl:text>,&#10;</xsl:text>
        <xsl:apply-templates select="title-group/article-title"/>
        <xsl:choose>
            <xsl:when test="contrib-group[@content-type='authors']">
                <xsl:apply-templates select="contrib-group[@content-type='authors']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="contrib-group"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="pub-date[@pub-type='pmc-release']">
                <xsl:apply-templates select="pub-date[@pub-type='pmc-release']"/>
            </xsl:when>
            <xsl:when test="pub-date[@pub-type='epub']">
                <xsl:apply-templates select="pub-date[@pub-type='epub']"/>
            </xsl:when>
            <xsl:when test="pub-date[@pub-type='ppub']">
                <xsl:apply-templates select="pub-date[@pub-type='ppub']"/>
            </xsl:when>
            <xsl:when test="pub-date[@date-type='pub']">
                <xsl:apply-templates select="pub-date[@date-type='pub']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="pub-date"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="kwd-group[@kwd-group-type='author']"/>
        <xsl:choose>
            <xsl:when test="abstract[not(@abstract-type)]">
                <xsl:apply-templates select="abstract[not(@abstract-type)]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="abstract[1]"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="volume"/>
        <xsl:apply-templates select="elocation-id"/>
        <xsl:apply-templates select="../journal-meta/journal-title-group/journal-title"/>
        <xsl:apply-templates select="../journal-meta/issn"/>
        <xsl:apply-templates select="article-id[@pub-id-type='pmc']"/>
        <xsl:apply-templates select="article-id[@pub-id-type='pmid']"/>
        <xsl:apply-templates select="article-id[@pub-id-type='doi']"/><!-- always at the end, to avoid trailing comma -->
        <xsl:text>}</xsl:text>
    </xsl:template>

    <!-- with brackets around the value -->
    <xsl:template name="item">
        <xsl:param name="key"/>
        <xsl:param name="value"/>
        <xsl:param name="suffix" select="','"/>
        <xsl:value-of select="concat('  ', $key, ' = {', $value, '}', $suffix, '&#10;')"/>
    </xsl:template>

    <!-- without brackets around the value -->
    <xsl:template name="raw-item">
        <xsl:param name="key"/>
        <xsl:param name="value"/>
        <xsl:param name="suffix" select="','"/>
        <xsl:value-of select="concat('  ', $key, ' = ', $value, $suffix, '&#10;')"/>
    </xsl:template>

    <xsl:template match="article-id[@pub-id-type='doi']">
        <xsl:call-template name="item">
            <xsl:with-param name="key">url</xsl:with-param>
            <xsl:with-param name="value" select="concat('https://doi.org/', .)"/>
        </xsl:call-template>

        <xsl:call-template name="item">
            <xsl:with-param name="key">doi</xsl:with-param>
            <xsl:with-param name="value" select="."/>
            <xsl:with-param name="suffix" select="''"/><!-- no trailing comma on the last entry -->
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="article-id[@pub-id-type='pmc']">
        <xsl:call-template name="item">
            <xsl:with-param name="key" select="@pub-id-type"/>
            <xsl:with-param name="value" select="concat('PMC', .)"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="article-id[@pub-id-type='pmid']">
        <xsl:call-template name="item">
            <xsl:with-param name="key" select="@pub-id-type"/>
            <xsl:with-param name="value" select="."/>
        </xsl:call-template>
    </xsl:template>

	<xsl:template match="article-title">
        <xsl:call-template name="item">
            <xsl:with-param name="key">title</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:apply-templates mode="markup"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="contrib-group">
        <xsl:call-template name="item">
            <xsl:with-param name="key">author</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:apply-templates select="contrib[@contrib-type='author']"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- contributors (authors and editors) -->
	<xsl:template match="contrib[@contrib-type='author']">
        <xsl:choose>
            <xsl:when test="name">
                <xsl:value-of select="name/surname"/>
                <xsl:apply-templates select="name/suffix" mode="name"/>
                <xsl:apply-templates select="name/given-names" mode="name"/>
            </xsl:when>
        </xsl:choose>

        <xsl:if test="position() != last()">
            <xsl:value-of select="' and '"/>
        </xsl:if>
	</xsl:template>

    <xsl:template match="given-names | suffix" mode="name">
        <xsl:value-of select="concat(', ', .)"/>
    </xsl:template>

    <xsl:template match="kwd-group[@kwd-group-type='author']">
        <xsl:call-template name="item">
            <xsl:with-param name="key">keywords</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:apply-templates select="kwd"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="kwd">
        <xsl:value-of select="."/>

        <xsl:if test="position() != last()">
            <xsl:value-of select="', '"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="pub-date">
        <xsl:apply-templates select="year"/>
        <xsl:apply-templates select="month"/>
    </xsl:template>

    <xsl:template match="year | volume">
        <xsl:call-template name="raw-item">
            <xsl:with-param name="key" select="local-name()"/>
            <xsl:with-param name="value" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="month">
        <xsl:call-template name="raw-item">
            <xsl:with-param name="key" select="local-name()"/>
            <xsl:with-param name="value">
                <xsl:value-of select="substring($month-abbreviations, number(.) * 3, 3)"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="abstract">
        <xsl:call-template name="item">
            <xsl:with-param name="key">abstract</xsl:with-param>
            <xsl:with-param name="value">
                <xsl:apply-templates mode="markup"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="elocation-id">
        <xsl:call-template name="item">
            <xsl:with-param name="key">pages</xsl:with-param>
            <xsl:with-param name="value" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="journal-title">
        <xsl:call-template name="item">
            <xsl:with-param name="key">journal</xsl:with-param>
            <xsl:with-param name="value" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="issn">
        <xsl:choose>
            <xsl:when test=".='0000-0000'">
                <!-- miss out the placeholder ISSN - 0000-0000 -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="item">
                    <xsl:with-param name="key">issn</xsl:with-param>
                    <xsl:with-param name="value" select="."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- formatting markup -->
    <!-- see http://www.tei-c.org/release/doc/tei-xsl-common2/slides/teilatex-slides3.html -->

    <xsl:template match="*" mode="markup">
        <xsl:apply-templates mode="markup"/>
    </xsl:template>

    <xsl:template match="bold" mode="markup">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="italic" mode="markup">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="underline" mode="markup">
        <xsl:text>\uline{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="overline" mode="markup">
        <xsl:text>\textoverbar{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="sup" mode="markup">
        <xsl:text>\textsuperscript{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="sub" mode="markup">
        <xsl:text>\textsubscript{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="sc" mode="markup">
        <xsl:text>\textsc{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="monospace" mode="markup">
        <xsl:text>\texttt{</xsl:text>
        <xsl:apply-templates mode="markup"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
</xsl:stylesheet>