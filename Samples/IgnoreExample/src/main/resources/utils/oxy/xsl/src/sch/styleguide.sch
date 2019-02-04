<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
	xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d2t="http://data2type.de/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xsl:key name="element-name" match="xsl:*" use="local-name()"/>

	<sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
    <sch:ns uri="http://data2type.de/" prefix="d2t"/>

    <sch:let name="includes" value="d2t:getAllIncludes(/)"/>

   <sch:pattern id="p_01_unused_items">
       
       <sch:rule context="*[@d2t:ignore = 'p_01_unused_items']"/>
        
       <sch:rule context="xsl:template[@name]" role="warn">
           <sch:assert test="$includes/key('element-name', 'call-template')/@name = @name"
               sqf:fix="delete ignore_p_01_unused_items">The template <sch:value-of select="@name"
               /> is never used. If this global template is used in some other related stylesheets, 
               please move it to your master file.</sch:assert>
           
           <sqf:fix id="ignore_p_01_unused_items">
               <sqf:description>
                   <sqf:title>Ignore this warning</sqf:title>
               </sqf:description>
               <sqf:add match="." target="d2t:ignore" node-type="attribute"
                   select="'p_01_unused_items'"/>
           </sqf:fix>
           
           <sqf:fix id="delete">
               <sqf:description>
                   <sqf:title>Delete this element.</sqf:title>
               </sqf:description>
               <sqf:delete/>
           </sqf:fix>
           
       </sch:rule>
        

		

	</sch:pattern>

    
    <xsl:function name="d2t:getAllIncludes" as="document-node()*">
        <xsl:param name="document" as="document-node()"/>
        <xsl:sequence select="d2t:getAllIncludes($document, true())"/>
    </xsl:function>
    
    <xsl:function name="d2t:getAllIncludes" as="document-node()*">
        <xsl:param name="document" as="document-node()"/>
        <xsl:param name="imports" as="xs:boolean"/>
        <xsl:variable name="includes" select="
            $document/*/(xsl:include | xsl:import[$imports])
            /@href[doc-available(resolve-uri(., base-uri(.)))]"/>
        <xsl:sequence select="
            $document | $includes/
            d2t:getAllIncludes(doc(resolve-uri(., base-uri(.))))"/>
    </xsl:function>

</sch:schema>
