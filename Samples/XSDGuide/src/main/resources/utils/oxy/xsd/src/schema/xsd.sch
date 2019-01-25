<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:es="http://www.escali.schematron-quickfix.com/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:d2t="http://www.data2type.de" queryBinding="xslt2" xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <xsl:include href="lib.xsl"/>

    <sch:ns uri="http://www.data2type.de" prefix="d2t"/>
    <sch:ns uri="http://www.w3.org/2001/XMLSchema" prefix="xs"/>
    <sch:ns uri="http://www.escali.schematron-quickfix.com/" prefix="es"/>
    <sch:let name="config" value="/xs:schema/xs:annotation/xs:appinfo/d2t:xsdguide"/>
    <sch:let name="status" value="($config/@status, 'inactive')[1]"/>
    <sch:let name="design-pattern" value="$config/@mode"/>

    <sch:let name="es-impl" value="function-available('es:getPhase')"/>
    <sch:let name="firstOrAll" value="
            if ($es-impl) then
                true()
            else
                1"/>
    <sch:let name="xsd-common-types" value="
            ('xs:string',
            'xs:boolean',
            'xs:integer',
            'xs:double',
            'xs:dateTime',
            'xs:date',
            'xs:time',
            'xs:token'
            )"/>
    <sch:let name="types-as-default" value="
            $xsd-common-types[if ($es-impl) then
                true()
            else
                1]
            "/>
    
    <sch:let name="isSalamiSlice" value="$design-pattern = 'salami-slice'"/>
    <sch:let name="isVenetianBlind" value="$design-pattern = 'venetian-blind'"/>

    <sch:pattern id="status">
        <sch:rule context="xs:schema">
            <sch:assert test="$status = 'active'" sqf:fix="setGuideActive" role="info">The XSD guide is inactive.</sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="mode">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="xs:schema" role="info">
            <sch:assert test="$design-pattern = ('venetian-blind', 'salami-slice')" sqf:fix="mode.venetian.blind mode.element.based setGuideInActive">Please select the basic XSD design pattern. Possible patterns are: "Venetian Blind" or "Salami Slice".</sch:assert>
            <sqf:fix id="mode.venetian.blind">
                <sqf:description>
                    <sqf:title>Choose the type Venetian Blind.</sqf:title>
                    <sqf:p>The Venetian Blind pattern will generate for each element top-level xsd:complexType or xsd:simpleType elements.</sqf:p>
                    <sqf:p>The local elements will refer to theese types by type attributes.</sqf:p>
                </sqf:description>
                <sqf:add match="$config" target="mode" node-type="attribute" select="'venetian-blind'"/>
            </sqf:fix>
            <sqf:fix id="mode.element.based">
                <sqf:description>
                    <sqf:title>Choose the Salami Slice pattern.</sqf:title>
                    <sqf:p>The Salami Slice pattern will genereate for each element top-level xsd:element elements.</sqf:p>
                    <sqf:p>The local element declarations will refer to theese elements by ref attributes.</sqf:p>
                </sqf:description>
                <sqf:add match="$config" target="mode" node-type="attribute" select="'salami-slice'"/>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="vb.root">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="xs:schema" role="info">
            <sch:assert test="xs:element" sqf:fix="vb.root.define sl.root.define">You should start with a root element</sch:assert>
            <sqf:fix id="vb.root.define" use-when="$isVenetianBlind">
                <sqf:description>
                    <sqf:title>Define a root element name</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.root.element.name">
                    <sqf:description>
                        <sqf:title>Please specify the local name of your root element.</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:element name="{$vb.root.element.name}" type="{$vb.root.element.name}Type"/>
                    <sqf:copy-of select="d2t:defComplexType($vb.root.element.name)"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.root.define" use-when="$isSalamiSlice">
                <sqf:description>
                    <sqf:title>Define a root element name</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.root.element.name">
                    <sqf:description>
                        <sqf:title>Please specify the local name of your root element.</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <sqf:copy-of select="d2t:defElementDef($vb.root.element.name)"/>
                </sqf:add>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="vb.content">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($isVenetianBlind)]"/>
        <sch:rule context="xs:complexType[not(xs:sequence | xs:choice)]" role="info">
            <sch:report test="xs:annotation/xs:appinfo/d2t:xsdguide/d2t:check-content" sqf:fix="vb.content.dtd vb.content.no">Do you need some children for the type <sch:value-of select="@name"/>?</sch:report>
            <sqf:fix id="vb.content.dtd">
                <sqf:description>
                    <sqf:title>Specify the content with DTD syntax</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add match="xs:annotation" position="after" select="d2t:createContentByDTD($vb.content.dtd.spec)"/>
                <sqf:add node-type="attribute" target="mixed" select="contains($vb.content.dtd.spec, '#PCDATA')"/>
            </sqf:fix>
            <sqf:fix id="vb.content.no">
                <sqf:description>
                    <sqf:title>No more children</sqf:title>
                </sqf:description>
                <sqf:delete match="d2t:guide-cleanup(., 'check-content')"/>
            </sqf:fix>
        </sch:rule>

    </sch:pattern>

    <sch:pattern icon="vb.elementType">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($design-pattern = 'venetian-blind')]"/>
        <sch:rule context="xs:complexType">
            <sch:let name="name" value="@name"/>
            <sch:let name="declWoType" value=".//xs:element[@name][not(xs:complexType)][not(@type)]"/>
            <sch:report test="$declWoType" sqf:fix="vb.elementType.allComplex">There are elements in the type <sch:value-of select="$name"/> without a type.</sch:report>
            
            <sqf:fix id="vb.elementType.allComplex">
                <sqf:description>
                    <sqf:title>Create for all a new complex type.</sqf:title>
                </sqf:description>
                <sqf:add position="after">
                    <xsl:for-each-group select="$declWoType" group-by="@name">
                        <sqf:copy-of select="d2t:defComplexType(current-grouping-key(), '')"/>
                    </xsl:for-each-group>
                </sqf:add>
                <sqf:add match="$declWoType" node-type="attribute" target="type">
                    <sch:value-of select="concat(@name, 'Type', '')"/>
                </sqf:add>
            </sqf:fix>
        </sch:rule>
        <sch:rule context="xs:element[@name][not(xs:complexType)]" role="info">
            <sch:let name="name" value="@name"/>
            <sch:assert test="@type" sqf:fix="vb.elementType.complexNew vb.elementType.complexReuse vb.elementType.simpleType vb.elementType.xsdtype">Please specify the type of the element <sch:value-of select="$name"/>.</sch:assert>
            <sqf:fix id="vb.elementType.simpleType">
                <sqf:description>
                    <sqf:title>Create a new custom simple type</sqf:title>
                </sqf:description>
                <sch:let name="countExist" value="count(/xs:schema/xs:simpleType[matches(@name, concat($name, 'Type\d*'))])"/>
                <sch:let name="suf" value="($countExist + 1)[. > 1]"/>
                <sqf:add match="ancestor::xs:complexType" position="after">
                    <xs:simpleType name="{$name}Type{$suf}">
                        <xs:annotation>
                            <xs:appinfo>
                                <d2t:xsdguide xmlns:d2t="http://www.data2type.de">
                                    <d2t:spec-simpleType/>
                                </d2t:xsdguide>
                            </xs:appinfo>
                        </xs:annotation>
                    </xs:simpleType>
                </sqf:add>
                <sqf:add node-type="attribute" target="type" select="concat($name, 'Type', $suf)"/>
            </sqf:fix>
            <sqf:fix id="vb.elementType.xsdtype">
                <sqf:description>
                    <sqf:title>Use a build in type</sqf:title>
                </sqf:description>
                <sqf:user-entry name="type" default="$types-as-default">
                    <sqf:description>
                        <sqf:title>Use one of the build-in types</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add node-type="attribute" target="type" select="$type"/>
            </sqf:fix>
            <sqf:fix id="vb.elementType.complexNew">
                <sqf:description>
                    <sqf:title>Create a new complex type</sqf:title>
                </sqf:description>
                <sch:let name="countExist" value="count(/xs:schema/xs:complexType[matches(@name, concat($name, 'Type\d*'))])"/>
                <sch:let name="suf" value="($countExist + 1)[. > 1]"/>
                <sqf:add match="ancestor::xs:complexType" position="after" select="d2t:defComplexType($name, $suf)"/>
                <sqf:add node-type="attribute" target="type" select="concat($name, 'Type', $suf)"/>
            </sqf:fix>
            <sqf:fix id="vb.elementType.complexReuse" use-for-each="/xs:schema/(xs:complexType | xs:simpleType)[matches(@name, concat($name, 'Type\d*'))]">
                <sch:let name="tName" value="$sqf:current/@name"/>
                <sqf:description>
                    <sqf:title>Reuse the <sch:value-of select="
                                if ($sqf:current/self::xs:complexType) then
                                    'complex'
                                else
                                    'simple'"/> type "<sch:value-of select="$tName"/>"</sqf:title>
                </sqf:description>
                <sqf:add node-type="attribute" target="type">
                    <sch:value-of select="$tName"/>
                </sqf:add>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>

    <!--    <sch:pattern id="vb.content"></sch:pattern>-->

    <sch:pattern id="vb.attribute">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($design-pattern = 'venetian-blind')]"/>
        <sch:rule context="xs:complexType" role="info">
            <sch:report test="xs:annotation/xs:appinfo/d2t:xsdguide/d2t:check-attributes" sqf:fix="vb.attribute.add.custom vb.attribute.add.oxy vb.attribute.add.es vb.attribute.no">Do you need some attributes for the type <sch:value-of select="@name"/>?</sch:report>

            <sqf:fix id="vb.attribute.add.custom">
                <sqf:description>
                    <sqf:title>Add attribute with custom type</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.attribute.add.custom.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$vb.attribute.add.custom.name}" type="{$vb.attribute.add.custom.name}Type"/>
                </sqf:add>
                <sqf:add match="/xs:schema" position="last-child">
                    <xs:simpleType name="{$vb.attribute.add.custom.name}Type">
                        <xs:annotation>
                            <xs:appinfo>
                                <d2t:xsdguide xmlns:d2t="http://www.data2type.de">
                                    <d2t:spec-simpleType/>
                                </d2t:xsdguide>
                            </xs:appinfo>
                        </xs:annotation>
                    </xs:simpleType>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="vb.attribute.add.es" use-when="$es-impl">
                <sqf:description>
                    <sqf:title>Add attribute with the an build-in type.</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.attribute.add.type" default="$types-as-default">
                    <sqf:description>
                        <sqf:title>Select the simple type</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:user-entry name="vb.attribute.add.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$vb.attribute.add.name}" type="{$vb.attribute.add.type}"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="vb.attribute.add.oxy" use-for-each="$xsd-common-types" use-when="not($es-impl)">
                <sch:let name="type" value="$sqf:current"/>
                <sqf:description>
                    <sqf:title>Add attribute with the type "<sch:value-of select="$type"/>"</sqf:title>
                </sqf:description>
                <sqf:user-entry name="vb.attribute.add.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$vb.attribute.add.name}" type="{$type}"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="vb.attribute.no">
                <sqf:description>
                    <sqf:title>No more attributes</sqf:title>
                </sqf:description>
                <sqf:delete match="d2t:guide-cleanup(., 'check-attributes')"/>
            </sqf:fix>
        </sch:rule>


    </sch:pattern>

    <sch:pattern id="g.simpleType">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="xs:simpleType" role="info">
            <sch:report test="xs:annotation/xs:appinfo/d2t:xsdguide/d2t:spec-simpleType" sqf:fix="g.simpleType.regex g.simpleType.enum">Please specify the simple type.</sch:report>
            <sqf:fix id="g.simpleType.regex">
                <sqf:description>
                    <sqf:title>Restrict the type via regex</sqf:title>
                </sqf:description>
                <sqf:user-entry name="g.simpleType.regex.pattern">
                    <sqf:description>
                        <sqf:title>Specify the regulare expression.</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:restriction base="xs:string">
                        <xs:pattern value="{$g.simpleType.regex.pattern}"/>
                    </xs:restriction>
                </sqf:add>
                <sqf:delete match="d2t:guide-cleanup(., 'spec-simpleType')"/>
            </sqf:fix>
            <sqf:fix id="g.simpleType.enum">
                <sqf:description>
                    <sqf:title>Specify a enumeration.</sqf:title>
                </sqf:description>
                <sqf:user-entry name="g.simpleType.enum.values">
                    <sqf:description>
                        <sqf:title>Specify all values by a comma-separated list.</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:user-entry name="g.simpleType.enum.base" default="$types-as-default">
                    <sqf:description>
                        <sqf:title>Specify the base type.</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:restriction base="{$g.simpleType.enum.base}">
                        <xsl:for-each select="tokenize($g.simpleType.enum.values, ',')">
                            <xs:enumeration value="{.}"/>
                        </xsl:for-each>
                    </xs:restriction>
                </sqf:add>
                <sqf:delete match="d2t:guide-cleanup(., 'spec-simpleType')"/>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="vb.check">
        <sch:rule context="node()[not($design-pattern = 'venetian-blind')]"/>
        <sch:rule context="xs:element">
            <sch:let name="ref" value="@ref"/>
            <sch:let name="refEl" value="/xs:schema/xs:element[@name = $ref]"/>
            <sch:report test="@ref" sqf:fix="vb.check.refAndCt.conversion vb.check.ref.conversion">Do not refer to other elements. The choosen design pattern states that with type attributes should refered to global types.</sch:report>
            <sqf:fix id="vb.check.refAndCt.conversion" use-when="$refEl/xs:complexType">
                <sqf:description>
                    <sqf:title>Convert element reference to type reference</sqf:title>
                </sqf:description>
                <sqf:replace match="$refEl">
                    <xs:complexType>
                        <xsl:copy-of select="xs:complexType/@*" copy-namespaces="no"/>
                        <xsl:attribute name="name" select="concat(@name, 'Type')"/>
                        <xsl:copy-of select="xs:complexType/node()" copy-namespaces="no"/>
                    </xs:complexType>
                </sqf:replace>
                <sqf:add target="type" node-type="attribute" select="concat(@ref, 'Type')"/>
                <sqf:add target="name" node-type="attribute" select="concat(@ref, '')"/>
                <sqf:delete match="@ref"/>
            </sqf:fix>

            <sqf:fix id="vb.check.ref.conversion" use-when="$refEl/@type and not($refEl/xs:complexType)">
                <sqf:description>
                    <sqf:title>Convert element reference to type reference</sqf:title>
                </sqf:description>
                <sqf:add target="type" node-type="attribute" select="concat($refEl/@type, '')"/>
                <sqf:add target="name" node-type="attribute" select="concat(@ref, '')"/>
                <sqf:delete match="@ref"/>
            </sqf:fix>

            <sch:let name="name" value="@name"/>
            <sch:report test="xs:complexType" sqf:fix="vb.check.complexType.conversion">Do not use local complex types. The choosen design pattern states that complex type should only be global.</sch:report>

            <sqf:fix id="vb.check.complexType.conversion">
                <sqf:description>
                    <sqf:title>Converts local to global complex type.</sqf:title>
                </sqf:description>
                <sch:let name="ct" value="xs:complexType"/>
                <sqf:add match="ancestor-or-self::* intersect /xs:schema/*" position="after">
                    <xs:complexType>
                        <xsl:copy-of select="$ct/@*" copy-namespaces="no"/>
                        <xsl:attribute name="name" select="concat($name, 'Type')"/>
                        <xsl:copy-of select="$ct/node()" copy-namespaces="no"/>
                    </xs:complexType>
                </sqf:add>
                <sqf:add target="type" node-type="attribute" select="concat($name, 'Type')"/>
                <sqf:delete match="$ct"/>
            </sqf:fix>

        </sch:rule>
    </sch:pattern>
    
<!--    
    Salami Slice
    -->
    
    <sch:pattern id="sl.content">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($isSalamiSlice)]"/>
        <sch:rule context="xs:element/xs:complexType[not(xs:sequence | xs:choice)]" role="info" subject="..">
            <sch:report test="xs:annotation/xs:appinfo/d2t:xsdguide/d2t:check-content" sqf:fix="sl.content.dtd sl.content.no">Do you need some children for the element <sch:value-of select="../@name"/>?</sch:report>
            <sqf:fix id="sl.content.dtd">
                <sqf:description>
                    <sqf:title>Specify the content with DTD syntax</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add match="xs:annotation" position="after" select="d2t:createContentByDTDforSalamiSlice($sl.content.dtd.spec)"/>
                <sqf:add node-type="attribute" target="mixed" select="contains($sl.content.dtd.spec, '#PCDATA')"/>
            </sqf:fix>
            <sqf:fix id="sl.content.no">
                <sqf:description>
                    <sqf:title>No more children</sqf:title>
                </sqf:description>
                <sqf:delete match="d2t:guide-cleanup(., 'check-content')"/>
            </sqf:fix>
        </sch:rule>
        
        <sch:rule context="xs:element/xs:complexType/xs:sequence/xs:* | xs:complexType/xs:choice/xs:*" role="info">
            <sch:let name="complexType" value="../.."/>
            <sch:report test="$complexType/xs:annotation/xs:appinfo/d2t:xsdguide/d2t:check-content" sqf:fix="sl.content.dtd.after sl.content.dtd.before sl.content.dtd.insert.first sl.content.dtd.insert.last sl.content.no">Do you want to add some children after/before this <sch:name/>?</sch:report>
            <sqf:fix id="sl.content.dtd.after">
                <sqf:description>
                    <sqf:title>Insert content after this <sch:name/></sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="after" select="d2t:createContentByDTDforSalamiSlice($sl.content.dtd.spec, false())"/>
                <sqf:add match="$complexType" node-type="attribute" target="mixed" select="contains($sl.content.dtd.spec, '#PCDATA') or $complexType/@mixed = 'true'"/>
            </sqf:fix>
            <sqf:fix id="sl.content.dtd.before">
                <sqf:description>
                    <sqf:title>Insert content before this <sch:name/></sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="before" select="d2t:createContentByDTDforSalamiSlice($sl.content.dtd.spec, false())"/>
                <sqf:add match="$complexType" node-type="attribute" target="mixed" select="contains($sl.content.dtd.spec, '#PCDATA') or $complexType/@mixed = 'true'"/>
            </sqf:fix>
            <sqf:fix id="sl.content.dtd.insert.first" use-when="self::xs:choice | self::xs:sequence">
                <sqf:description>
                    <sqf:title>Insert content into this <sch:name/> (at the beginning).</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="first-child" select="d2t:createContentByDTDforSalamiSlice($sl.content.dtd.spec, false())"/>
            </sqf:fix>
            <sqf:fix id="sl.content.dtd.insert.last" use-when="(self::xs:choice | self::xs:sequence)/*">
                <sqf:description>
                    <sqf:title>Insert content into this <sch:name/> (at the end).</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.content.dtd.spec">
                    <sqf:description>
                        <sqf:title>Use the usual DTD syntax to specify the content</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child" select="d2t:createContentByDTDforSalamiSlice($sl.content.dtd.spec, false())"/>
            </sqf:fix>
            <sqf:fix id="sl.content.no">
                <sqf:description>
                    <sqf:title>No more children for this element!</sqf:title>
                </sqf:description>
                <sqf:delete match="d2t:guide-cleanup($complexType, 'check-content')"/>
            </sqf:fix>
        </sch:rule>
        
        
        
    </sch:pattern>
    
    <sch:pattern icon="sl.elementType">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($isSalamiSlice)]"/>
        <sch:rule context="xs:element[@ref]" role="info">
            <sch:let name="ref" value="@ref"/>
            <sch:assert test="/xs:schema/xs:element[@name = $ref]" sqf:fix="sl.elementType.complexNew sl.elementType.simpleType sl.elementType.xsdtype">Please add a declaration for the element <sch:value-of select="$ref"/>.</sch:assert>
            <sqf:fix id="sl.elementType.simpleType">
                <sqf:description>
                    <sqf:title>Create a declaration with a custom simple type</sqf:title>
                </sqf:description>
                <sqf:add match="ancestor::xs:element" position="after">
                    <xs:element name="{$ref}">
                        <xs:simpleType>
                            <xs:annotation>
                                <xs:appinfo>
                                    <d2t:xsdguide xmlns:d2t="http://www.data2type.de">
                                        <d2t:spec-simpleType/>
                                    </d2t:xsdguide>
                                </xs:appinfo>
                            </xs:annotation>
                        </xs:simpleType>
                    </xs:element>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.elementType.xsdtype">
                <sqf:description>
                    <sqf:title>Create an element declaration with a build-in type</sqf:title>
                </sqf:description>
                <sqf:user-entry name="type" default="$types-as-default">
                    <sqf:description>
                        <sqf:title>Use one of the build-in types</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add match="ancestor::xs:element" position="after">
                    <xs:element name="{$ref}" type="{$type}"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.elementType.complexNew">
                <sqf:description>
                    <sqf:title>Create an element declaration with a complex type</sqf:title>
                </sqf:description>
                <sqf:add match="ancestor::xs:element" position="after">
                    <sqf:copy-of select="d2t:defElementDef($ref)"/>
                </sqf:add>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="sl.attribute">
        <sch:rule context="node()[$status = 'inactive']"/>
        <sch:rule context="node()[not($isSalamiSlice)]"/>
        
        <sch:rule context="xs:element/xs:complexType" role="info" subject="parent::*">
            <sch:report test="xs:annotation/xs:appinfo/d2t:xsdguide/d2t:check-attributes" sqf:fix="sl.attribute.add.custom sl.attribute.add.oxy sl.attribute.add.es sl.attribute.no">Do you need some attributes for the element <sch:value-of select="../@name"/>?</sch:report>
            
            <sqf:fix id="sl.attribute.add.custom">
                <sqf:description>
                    <sqf:title>Add attribute with custom type</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.attribute.add.custom.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$sl.attribute.add.custom.name}">
                        <xs:simpleType>
                            <xs:annotation>
                                <xs:appinfo>
                                    <d2t:xsdguide xmlns:d2t="http://www.data2type.de">
                                        <d2t:spec-simpleType/>
                                    </d2t:xsdguide>
                                </xs:appinfo>
                            </xs:annotation>
                        </xs:simpleType>
                    </xs:attribute>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.attribute.add.es" use-when="$es-impl">
                <sqf:description>
                    <sqf:title>Add attribute with the an build-in type.</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.attribute.add.type" default="$types-as-default">
                    <sqf:description>
                        <sqf:title>Select the simple type</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:user-entry name="sl.attribute.add.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$sl.attribute.add.name}" type="{$sl.attribute.add.type}"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.attribute.add.oxy" use-for-each="$xsd-common-types" use-when="not($es-impl)">
                <sch:let name="type" value="$sqf:current"/>
                <sqf:description>
                    <sqf:title>Add attribute with the type "<sch:value-of select="$type"/>"</sqf:title>
                </sqf:description>
                <sqf:user-entry name="sl.attribute.add.name">
                    <sqf:description>
                        <sqf:title>Specifiy the local name</sqf:title>
                    </sqf:description>
                </sqf:user-entry>
                <sqf:add position="last-child">
                    <xs:attribute name="{$sl.attribute.add.name}" type="{$type}"/>
                </sqf:add>
            </sqf:fix>
            <sqf:fix id="sl.attribute.no">
                <sqf:description>
                    <sqf:title>No more attributes</sqf:title>
                </sqf:description>
                <sqf:delete match="d2t:guide-cleanup(., 'check-attributes')"/>
            </sqf:fix>
        </sch:rule>
        
    </sch:pattern>
    

    <sqf:fixes>
        <sqf:fix id="setGuideActive">
            <sqf:description>
                <sqf:title>Set the XSD guide active</sqf:title>
            </sqf:description>
            <sqf:add match="$config" node-type="attribute" target="status" select="'active'" use-when="$config"/>
            <sqf:add match="/xs:schema" position="first-child" use-when="not($config)">
                <xs:annotation>
                    <xs:appinfo>
                        <d2t:xsdguide status="active"/>
                    </xs:appinfo>
                </xs:annotation>
            </sqf:add>
        </sqf:fix>
        <sqf:fix id="setGuideInActive">
            <sqf:description>
                <sqf:title>Deactivate the XSD guide</sqf:title>
            </sqf:description>
            <sqf:add match="$config" node-type="attribute" target="status" select="'inactive'" use-when="$config"/>
        </sqf:fix>

    </sqf:fixes>
</sch:schema>
