<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d2t="http://www.data2type.de" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.0">
    <xsl:function name="d2t:guide-cleanup" as="node()">
        <xsl:param name="context" as="element()"/>
        <xsl:param name="delete" as="xs:string"/>
        <xsl:variable name="deleteEl" select="$context/xs:annotation/xs:appinfo/d2t:xsdguide/*[local-name() = $delete]"/>
        <xsl:variable name="guide" select="$deleteEl/parent::*[not(* except $deleteEl)]"/>
        <xsl:variable name="appInfo" select="$guide/parent::*[not(* except $guide)]"/>
        <xsl:variable name="annotation" select="$appInfo/parent::*[not(* except $appInfo)]"/>
        <xsl:sequence select="($annotation, $appInfo, $guide, $deleteEl)[1]"/>
    </xsl:function>

    <xsl:variable name="syntax" select="
            map {
                '(': 'ob',
                ')': 'cb',
                '*': 'm',
                '?': 'm',
                '+': 'm',
                ',': 'c',
                '|': 'p'
            }"/>


    <xsl:function name="d2t:createContentByDTDforSalamiSlice">
        <xsl:param name="dtd.syntax" as="xs:string"/>
        <xsl:sequence select="d2t:createContentByDTDforSalamiSlice($dtd.syntax, true())"/>
    </xsl:function>
    <xsl:function name="d2t:createContentByDTDforSalamiSlice">
        <xsl:param name="dtd.syntax" as="xs:string"/>
        <xsl:param name="forceWrapper" as="xs:boolean"/>
        <xsl:sequence select="d2t:createContentByDTD($dtd.syntax, $forceWrapper, 'salami-slice')"/>
    </xsl:function>

    <xsl:function name="d2t:createContentByDTD" as="element()">
        <xsl:param name="dtd.syntax" as="xs:string"/>
        <xsl:sequence select="d2t:createContentByDTD($dtd.syntax, true())"/>
    </xsl:function>

    <xsl:function name="d2t:createContentByDTD" as="element()*">
        <xsl:param name="dtd.syntax" as="xs:string"/>
        <xsl:param name="forceWrapper" as="xs:boolean"/>
        <xsl:sequence select="d2t:createContentByDTD($dtd.syntax, $forceWrapper, 'venetian-blind')"/>
    </xsl:function>

    <xsl:function name="d2t:createContentByDTD" as="element()*">
        <xsl:param name="dtd.syntax" as="xs:string"/>
        <xsl:param name="forceWrapper" as="xs:boolean"/>
        <xsl:param name="design-pattern" as="xs:string"/>
        <xsl:variable name="parsed" as="element()*">
            <xsl:analyze-string select="$dtd.syntax" regex="([()*?+,|])|(\s+)|\{{([^}}]+)\}}">
                <xsl:matching-substring>
                    <xsl:variable name="char" select="regex-group(1)"/>
                    <xsl:variable name="spec-m" select="regex-group(3)"/>
                    <xsl:choose>
                        <xsl:when test="$char != ''">
                            <xsl:variable name="name" select="$syntax($char)"/>
                            <xsl:element name="{$name}">
                                <xsl:if test="$name = 'm'">
                                    <xsl:attribute name="type" select="$char"/>
                                </xsl:if>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$spec-m != ''">
                            <m type="{$spec-m}"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:if test=". != '#PCDATA'">
                        <e type="{.}"/>
                    </xsl:if>
                </xsl:non-matching-substring>
                <xsl:fallback/>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:variable name="multiplier" as="element()*">
            <xsl:for-each-group select="$parsed" group-ending-with="m">
                <xsl:variable name="parsed" select="current-group()"/>
                <xsl:variable name="m" select="$parsed[last()]/self::m"/>
                <xsl:choose>
                    <xsl:when test="$m">
                        <xsl:variable name="rest" select="$parsed except $m"/>
                        <xsl:variable name="anchor" select="$rest[last()]"/>
                        <xsl:variable name="rest" select="$rest except $anchor"/>
                        <xsl:sequence select="$rest"/>
                        <xsl:for-each select="$anchor">
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:attribute name="m" select="$m/@type"/>
                                <xsl:copy-of select="node()"/>
                            </xsl:copy>

                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$parsed"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>

        <xsl:variable name="brackets" select="d2t:bracket-resolution($multiplier)"/>


        <xsl:variable name="toplevel-type" select="
                if ($brackets/p and $brackets/c) then
                    ('mixed')
                else
                    if ($brackets/p) then
                        ('choice')
                    else
                        if (count($brackets/*) = 1 and $brackets/b or not($forceWrapper)) then
                            ('')
                        else
                            ('sequence')
                "/>
        <xsl:variable name="xsd-with-mixed" as="element()*">
            <xsl:choose>
                <xsl:when test="$toplevel-type = ''">
                    <xsl:apply-templates select="$brackets" mode="d2t:dtd2xsd">
                        <xsl:with-param name="design-pattern" select="$design-pattern" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="xs:{$toplevel-type}">
                        <xsl:apply-templates select="$brackets" mode="d2t:dtd2xsd">
                            <xsl:with-param name="design-pattern" select="$design-pattern" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:apply-templates select="$xsd-with-mixed" mode="d2t:mixed-resolve"/>
    </xsl:function>

    <xsl:template match="b[c and p]" mode="d2t:dtd2xsd" priority="10">
        <xs:mixed>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xs:mixed>
    </xsl:template>

    <xsl:template match="b[c] | b[not(*)]" mode="d2t:dtd2xsd">
        <xs:sequence>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xs:sequence>
    </xsl:template>

    <xsl:template match="b[p]" mode="d2t:dtd2xsd">
        <xs:choice>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xs:choice>
    </xsl:template>

    <xsl:template match="c | p | @type" mode="d2t:dtd2xsd"/>

    <xsl:template match="*[../p and ../c]" mode="d2t:dtd2xsd" priority="20">
        <xsl:variable name="next-match" as="element()?">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:variable name="next-separators" select="preceding-sibling::*[1] | following-sibling::*[1]"/>
        <xsl:for-each select="$next-match">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:if test="$next-separators/self::p">
                    <xsl:attribute name="d2t:choiceInMixed" select="true()"/>
                </xsl:if>
                <xsl:copy-of select="node()"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="e" mode="d2t:dtd2xsd">
        <xsl:param name="design-pattern" tunnel="yes" select="'venetian-blind'"/>
        <xs:element>
            <xsl:attribute name="{
                if ($design-pattern = 'venetian-blind') 
                then ('name') 
                else ('ref')
                }" select="@type"/>
            <xsl:apply-templates select="@*" mode="#current"/>
        </xs:element>
    </xsl:template>

    <xsl:template match="@m[. = '+']" mode="d2t:dtd2xsd">
        <xsl:attribute name="maxOccurs" select="'unbounded'"/>
    </xsl:template>

    <xsl:template match="@m[. = '*']" mode="d2t:dtd2xsd">
        <xsl:attribute name="minOccurs" select="0"/>
        <xsl:attribute name="maxOccurs" select="'unbounded'"/>
    </xsl:template>

    <xsl:template match="@m[. = '?']" mode="d2t:dtd2xsd">
        <xsl:attribute name="minOccurs" select="0"/>
    </xsl:template>

    <xsl:template match="@m" mode="d2t:dtd2xsd">
        <xsl:variable name="tokens" select="tokenize(., ':') ! normalize-space(.)"/>
        <xsl:if test="not($tokens[1] = ('1', ''))">
            <xsl:attribute name="minOccurs" select="$tokens[1]"/>
        </xsl:if>
        <xsl:if test="not($tokens[2] = '1')">
            <xsl:attribute name="maxOccurs" select="
                    if ($tokens[2] = '') then
                        ('unbounded')
                    else
                        ($tokens[2])"/>
        </xsl:if>
    </xsl:template>


    <xsl:template match="xs:mixed" mode="d2t:mixed-resolve">
        <xs:sequence>
            <xsl:for-each-group select="*" group-adjacent="@d2t:choiceInMixed = 'true'">
                <xsl:choose>
                    <xsl:when test="current-grouping-key()">
                        <xs:choice>
                            <xsl:apply-templates select="current-group()" mode="#current"/>
                        </xs:choice>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group()" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xs:sequence>
    </xsl:template>

    <xsl:template match="@d2t:choiceInMixed" mode="d2t:mixed-resolve"/>




    <!-- 
        copies all nodes:
    -->
    <xsl:template match="node() | @*" mode="d2t:mixed-resolve d2t:dtd2xsd">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>


    <xsl:function name="d2t:bracket-resolution" as="document-node()">
        <xsl:param name="parsed-flat" as="element()*"/>
        <xsl:variable name="depest-grouping">
            <xsl:for-each-group select="$parsed-flat" group-starting-with="ob">
                <xsl:variable name="group" select="current-group()"/>
                <xsl:variable name="ob" select="$group/self::ob"/>
                <xsl:choose>
                    <xsl:when test="$ob and $group/self::cb">
                        <xsl:for-each-group select="$group" group-ending-with="cb">
                            <xsl:variable name="group" select="current-group()"/>
                            <xsl:variable name="cb" select="$group/self::cb"/>
                            <xsl:choose>
                                <xsl:when test="$cb and position() = 1">
                                    <b>
                                        <xsl:copy-of select="($ob | $cb)/@*"/>
                                        <xsl:copy-of select="$group except ($cb, $ob)"/>
                                    </b>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$group"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$group"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:document>
            <xsl:copy-of select="
                    if ($depest-grouping/ob) then
                        (d2t:bracket-resolution($depest-grouping/*))
                    else
                        ($depest-grouping/*)"/>
        </xsl:document>
    </xsl:function>

    <xsl:function name="d2t:defComplexType" as="element(xs:complexType)">
        <xsl:param name="name" as="xs:string"/>
        <xsl:sequence select="d2t:defComplexType($name, '')"/>
    </xsl:function>

    <xsl:function name="d2t:defComplexType" as="element(xs:complexType)">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="suf" as="xs:string?"/>
        <xs:complexType name="{$name}Type{$suf}">
            <xs:annotation>
                <xs:appinfo>
                    <d2t:xsdguide>
                        <d2t:check-content/>
                        <d2t:check-attributes/>
                    </d2t:xsdguide>
                </xs:appinfo>
            </xs:annotation>
            <!--            <xs:sequence>
                <xs:annotation>
                    <xs:appinfo>
                        <d2t:xsdguide>
                        </d2t:xsdguide>
                    </xs:appinfo>
                </xs:annotation>
            </xs:sequence>-->
        </xs:complexType>
    </xsl:function>

    <xsl:function name="d2t:defElementDef">
        <xsl:param name="name" as="xs:string"/>
        <xs:element name="{$name}">
            <xs:complexType>
                <xs:annotation>
                    <xs:appinfo>
                        <d2t:xsdguide>
                            <d2t:check-content/>
                            <d2t:check-attributes/>
                        </d2t:xsdguide>
                    </xs:appinfo>
                </xs:annotation>
            </xs:complexType>
        </xs:element>
    </xsl:function>

    <xsl:function name="d2t:createDTDbyXSD" as="xs:string">
        <xsl:param name="xsdElement" as="element()?"/>
        <xsl:sequence select="d2t:createDTDbyXSD($xsdElement, false())"/>
    </xsl:function>

    <xsl:function name="d2t:createDTDbyXSD" as="xs:string">
        <xsl:param name="xsdElement" as="element()?"/>
        <xsl:param name="mixed" as="xs:boolean"/>
        <xsl:variable name="value">
            <xsl:apply-templates select="$xsdElement" mode="d2t:xsd2dtd">
                <xsl:with-param name="mixed" select="$mixed"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="result" select="string-join($value)"/>
        <xsl:variable name="result">
            <xsl:analyze-string select="$result" regex="^\((.*)\)$">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:value-of select="$result"/>
    </xsl:function>
    <xsl:function name="d2t:createDTDMultiplier" as="xs:string">
        <xsl:param name="xsdElement" as="element()"/>
        <xsl:variable name="min" select="($xsdElement/@minOccurs, '1')[1]"/>
        <xsl:variable name="max" select="($xsdElement/@maxOccurs, '1')[1]"/>
        <xsl:choose>
            <xsl:when test="$min = ('0', '1') and $max = ('1', 'unbounded')">
                <xsl:sequence select="
                        if ($min = '1' and $max = '1') then
                            ('')
                        else
                            if ($min = '0' and $max = '1') then
                                ('?')
                            else
                                if ($min = '0' and $max = 'unbounded') then
                                    ('*')
                                else
                                    if ($min = '1' and $max = 'unbounded') then
                                        ('+')
                                    else
                                        ('')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="max" select="
                        if ($max = 'unbounded') then
                            ('')
                        else
                            ($max)"/>
                <xsl:sequence select="concat('{', $min, ':', $max, '}')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="xs:sequence | xs:choice" mode="d2t:xsd2dtd">
        <xsl:param name="mixed" select="false()"/>
        <xsl:variable name="content" as="element()*">
            <xsl:if test="$mixed">
                <xs:text/>
            </xsl:if>
            <xsl:copy-of select="*"/>
        </xsl:variable>

        <xsl:variable name="content" as="xs:string*">
            <xsl:apply-templates select="$content" mode="d2t:xsd2dtd"/>
        </xsl:variable>
        <xsl:variable name="sep" select="
                if (self::xs:sequence) then
                    (', ')
                else
                    (' | ')"/>
        <xsl:variable name="mulitplier" select="d2t:createDTDMultiplier(.)"/>

        <xsl:variable name="withBrackets" select="$mulitplier != '' or self::xs:sequence or $mixed"/>
        <xsl:variable name="result">
            <xsl:if test="$withBrackets">
                <xsl:text>(</xsl:text>
            </xsl:if>
            <xsl:value-of select="string-join($content, $sep)"/>
            <xsl:if test="$withBrackets">
                <xsl:text expand-text="yes">){$mulitplier}</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="$result" separator=""/>
    </xsl:template>

    <xsl:template match="xs:text" mode="d2t:xsd2dtd">
        <xsl:text>#PCDATA</xsl:text>
    </xsl:template>

    <xsl:template match="xs:element" mode="d2t:xsd2dtd">
        <xsl:value-of select="@name || d2t:createDTDMultiplier(.)"/>
    </xsl:template>

    <xsl:template match="node()" mode="d2t:xsd2dtd"> </xsl:template>

</xsl:stylesheet>
