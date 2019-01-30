<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process" queryBinding="xslt2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <!-- SIMPLE STYLING RULES -->
  <sch:pattern>
    <!-- Title - styling elements are not allowed in title. -->
    <sch:rule context="title">
      <sch:report test="b" sqf:fix="resolveBold" role="warn" subject="b"> 
        Bold element is not allowed in title.</sch:report>
      
      <!-- Quick fix that converts a bold element into text -->
      <sqf:fix id="resolveBold">
        <sqf:description>
          <sqf:title>Change the bold element into text</sqf:title>
          <sqf:p>Removes the bold (b) markup and keeps the text content.</sqf:p>
        </sqf:description>
        <sqf:replace match="b" select="node()"/>
      </sqf:fix>
    </sch:rule>

    <!-- Ordered list assert -->
    <sch:rule context="ol">
      <sch:assert test="false()" sqf:fix="convertOLinUL" role="error"> Ordered lists are not
        allowed, use unordered lists instead.</sch:assert>
      
      <!-- Quick fix that converts an ordered list into an unordered one. -->
      <sqf:fix id="convertOLinUL">
        <sqf:description>
          <sqf:title>Convert ordered list to unordered list</sqf:title>
        </sqf:description>
        <sqf:replace target="ul" node-type="element">
          <xsl:apply-templates mode="copyExceptClass" select="@* | node()"/>
        </sqf:replace>
      </sqf:fix>
    </sch:rule>
    
    <sch:rule context="li">
      <!-- The list item must not end with semicolon -->
      <sch:report test="boolean(ends-with(text()[last()], ';'))" sqf:fix="removeSemicolon replaceSemicolon"
        role="warn"> Semicolon is not allowed after list item.</sch:report>
      
      <!-- Quick fix that removes the semicolon from list item. -->
      <sqf:fix id="removeSemicolon">
        <sqf:description>
          <sqf:title>Remove semicolon</sqf:title>
        </sqf:description>
        <sqf:stringReplace match="text()[last()]" regex=";$"/>
      </sqf:fix>
      
      <!-- Quick fix that replace the semicolon with full stop (.). -->
      <sqf:fix id="replaceSemicolon" use-when="position() = last()">
        <sqf:description>
          <sqf:title>Replace semicolon with full stop</sqf:title>
        </sqf:description>
        <sqf:stringReplace match="text()[last()]" regex=";$" select="'.'"/>
      </sqf:fix>
    </sch:rule>
    
    <!-- Unordered list asserts -->
    <sch:rule context="ul">
      <!-- Check the level of nested lists -->
      <sch:report test="count(ancestor::ul) >= 2" sqf:fix="plain" role="error"> There are too many levels in
        this list </sch:report>
      
      <!-- Check that there is more that one lit item in a list -->
      <sch:assert test="count(li) > 1" sqf:fix="addListItem plain" role="warn"> A list must have more than
        one item </sch:assert>
      
      <!-- Quick fix that converts a list into text -->
      <sqf:fix id="plain">
        <sqf:description>
          <sqf:title>Resolve the list into plain text</sqf:title>
          <sqf:p>The list will be converted into plain text.</sqf:p>
          <sqf:p>The text content of the list will be added as text.</sqf:p>
        </sqf:description>
        <sqf:replace match=". | .//ul">
          <xsl:apply-templates mode="copyExceptClass" select="li/node()"/>
        </sqf:replace>
      </sqf:fix>
      
      <!-- Quick fix that adds a new list item -->
      <sqf:fix id="addListItem">
        <sqf:description>
          <sqf:title>Add new list item</sqf:title>
          <sqf:p>Add a new list item as last item in the list</sqf:p>
        </sqf:description>
        <sqf:add node-type="element" target="li" position="last-child"/>
      </sqf:fix>
    </sch:rule>

    <!-- Report if link same as @href test value -->
    <sch:rule context="*[contains(@class, ' topic/xref ') or contains(@class, ' topic/link ')]">
      <sch:report test="@scope='external' and @href=text()" sqf:fix="removeText" role="warn">
        Link text is same as @href attribute value. Please remove.
      </sch:report>
      <sqf:fix id="removeText">
        <sqf:description>
          <sqf:title>Remove redundant link text, text is same as @href value.</sqf:title>
        </sqf:description>
        <sqf:delete match="text()"/>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- EDITING CONSISTENCY RULES -->
  <sch:pattern>
    <!-- Topic ID must be equal to name -->
    <sch:rule context="/*[1][contains(@class, ' topic/topic ')]">
      <sch:let name="reqId" value="substring-before(tokenize(document-uri(/), '/')[last()], '.')"/>
      <sch:assert test="@id = $reqId" sqf:fix="setId">
        Topic ID must be equal to file name.
      </sch:assert>
      <sqf:fix id="setId">
        <sqf:description>
          <sqf:title>Set "<sch:value-of select="$reqId"/>" as a topic ID</sqf:title>
          <sqf:p>The topic ID must be equal to the file name.</sqf:p>
        </sqf:description>
        <sqf:add node-type="attribute" target="id" select="$reqId"/>
      </sqf:fix>
    </sch:rule>
  
    <!-- Add Ids to all sections, in this way you can easly refer the section from documentation -->
    <sch:rule context="*[contains(@class, ' topic/section ') and not(contains(@class, ' task/')) and not(contains(@class, ' glossentry/'))]">
      <sch:assert test="@id" sqf:fix="addId addIds" role="warn">All sections should have an @id attribute</sch:assert>
      
      <sqf:fix id="addId">
        <sqf:description>
          <sqf:title>Add @id to the current section</sqf:title>
          <sqf:p>Add an @id attribute to the current section. The ID is generated from the section title.</sqf:p>
        </sqf:description>
        
        <!-- Generate an id based on the section title. If there is no title then generate a random id. -->
        <sqf:add target="id" node-type="attribute"
          select="if (exists(title) and string-length(title) > 0) 
          then substring(lower-case(replace(replace(normalize-space(string(title)), '\s', '_'), '[^a-zA-Z0-9_]', '')), 0, 50) 
          else generate-id()"/>
      </sqf:fix>
      
      <sqf:fix id="addIds">
        <sqf:description>
          <sqf:title>Add @id to all sections</sqf:title>
          <sqf:p>Add an @id attribute to each section from the document. The ID is generated from the section title.</sqf:p>
        </sqf:description>
        <!-- Generate an id based on the section title. If there is no title then generate a random id. -->
        <sqf:add match="//section[not(@id)]" target="id" node-type="attribute" 
          select="if (exists(title) and string-length(title) > 0) 
          then substring(lower-case(replace(replace(normalize-space(string(title)), '\s', '_'), '[^a-zA-Z0-9_]', '')), 0, 50) 
          else generate-id()"/>
      </sqf:fix>
    </sch:rule>

    <!-- Report ul after ul -->
    <sch:rule context="*[contains(@class, ' topic/ul ')]">
      <sch:report test="following-sibling::element()[1][contains(@class, ' topic/ul ')]" role="warn" sqf:fix="mergeLists"> Two
        consecutive unordered lists. You can probably merge them into one. </sch:report>
      
      <sqf:fix id="mergeLists">
        <sqf:description>
          <sqf:title>Merge lists into one</sqf:title>
        </sqf:description>
        <sqf:add position="last-child">
          <xsl:apply-templates mode="copyExceptClass" select="following-sibling::element()[1]/node()"/>
        </sqf:add>
        <sqf:delete match="following-sibling::element()[1]"/>
      </sqf:fix>
    </sch:rule>

    <!-- Image without any kind of reference -->
    <sch:rule context="*[contains(@class, ' topic/image ')]">
      <sch:report test="not(@href) and not(@keyref) and not(@conref) and not(@conkeyref)" sqf:fix="add_href add_keyref add_conref add_conkeyref"> Image without
        a reference. </sch:report>
      
      <sqf:fix id="add_href">
        <sqf:description>
          <sqf:title>Add @href attribute</sqf:title>
        </sqf:description>
        <sqf:add node-type="attribute" target="href"/>
      </sqf:fix>
      
      <sqf:fix id="add_keyref">
        <sqf:description>
          <sqf:title>Add @keyref attribute</sqf:title>
        </sqf:description>
        <sqf:add node-type="attribute" target="keyref"/>
      </sqf:fix>
      
      <sqf:fix id="add_conref">
        <sqf:description>
          <sqf:title>Add @conref attribute</sqf:title>
        </sqf:description>
        <sqf:add node-type="attribute" target="conref"/>
      </sqf:fix>
      
      <sqf:fix id="add_conkeyref">
        <sqf:description>
          <sqf:title>Add @conkeyref attribute</sqf:title>
        </sqf:description>
        <sqf:add node-type="attribute" target="conkeyref"/>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- STRUCTURE RULES -->
  <sch:pattern>
    <!-- Table asserts -->
    <sch:rule context="table">
      <sch:let name="minColumsNo" value="min(//row/count(entry))"/>
      <sch:let name="reqColumsNo" value="max(//row/count(entry))"/>
      
      <!-- Check the number of cells on each row -->
      <sch:assert test="$minColumsNo >= $reqColumsNo" sqf:fix="addCells">Cells are missing. (The
        number of cells for each row must be <sch:value-of select="$reqColumsNo"/>)</sch:assert>
      
      <!-- Quick fix that adds the missing cells from a table. -->
      <sqf:fix id="addCells">
        <sqf:description>
          <sqf:title>Add enough empty cells on each row</sqf:title>
          <sqf:p>Add enough empty cells on each row to match the required number of cells.</sqf:p>
        </sqf:description>
        <sqf:add match="//row" position="last-child">
          <sch:let name="columnNo" value="count(entry)"/>
          <xsl:for-each select="1 to xs:integer($reqColumsNo - $columnNo)">
            <entry/>
            <xsl:text>
						</xsl:text>
          </xsl:for-each>
        </sqf:add>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- OUTPUT RULES -->
  <sch:ns uri="http://www.oxygenxml.com/customFunction" prefix="oxyF"/>
  <sch:pattern>
    <!-- Report cases when the lines in a codeblock exceeds 80 characters -->
    <sch:rule context="*[contains(@class, ' pr-d/codeblock ')]" role="warn">
      <sch:let name="offendingLines" value="oxyF:lineLengthCheck(string(), 80)"/>
      <sch:report test="string-length($offendingLines) > 0">
        Lines in codeblocks should not exceed 80 characters. 
        (<sch:value-of select="$offendingLines"/>) </sch:report>
    </sch:rule>

    <!-- The text is not allowed directly in the section, it should be in a paragraph. Otherwise the output will be rendered with no space after the section -->
    <sch:rule context="*[contains(@class, ' topic/section ')]/text()[string-length(normalize-space(.)) > 0]">
      <sch:report test="true()" role="warn" subject="child::node()[1]" sqf:fix="wrapInParagraph">
        The text in a section element should be in a paragraph.</sch:report>
      
      <!-- Wrap the current element in a paragraph. -->
      <sqf:fix id="wrapInParagraph">
        <sqf:description>
          <sqf:title>Wrap text in a paragraph</sqf:title>
        </sqf:description>
        <sqf:replace node-type="element" target="p">
          <xsl:apply-templates mode="copyExceptClass" select="."/>
        </sqf:replace>
        <sqf:delete/>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- Automatic tagging -->
  <sch:pattern>
    <sch:rule context="text()[matches(., '(http|www)\S+')][local-name(parent::node()) != 'xref']">
      <sch:report test="true()" role="warn" sqf:fix="convertToLink">
        Link detected in '<sch:value-of select="local-name(parent::node())"/>' element</sch:report>
      
      <sqf:fix id="convertToLink">
        <!-- Get the link value -->
        <xsl:variable name="linkValue">
          <xsl:analyze-string select="." regex="(http|www)\S+">
            <xsl:matching-substring>
              <xsl:value-of select="regex-group(0)"/>
            </xsl:matching-substring>
          </xsl:analyze-string>
        </xsl:variable>
        
        <sqf:description>
          <sqf:title>Convert '<sch:value-of select="$linkValue"/>' text link to xref</sqf:title>
        </sqf:description>
        <sqf:stringReplace regex="(http|www)\S+">
          <xref href="{$linkValue}" format="html"/>
        </sqf:stringReplace>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- msgblock, screen, pre -> codeblock -->
  <sch:pattern>
    <sch:rule context="msgblock | screen | pre"> 
      <sch:report test="true()" sqf:fix="replaceWithCodeBlock">
        You should not use <sch:name/> element because it is not rendered properly in the output. Use a "codeblock" element instead.        
      </sch:report>
      
      <!-- Quick fix that converts an ordered list into an unordered one. -->
      <sqf:fix id="replaceWithCodeBlock">
        <sqf:description>
          <sqf:title>Replace <sch:name/> with codeblock</sqf:title>
        </sqf:description>
        <sqf:replace target="codeblock" node-type="element">
          <xsl:apply-templates mode="copyExceptClass" select="@* | node()"/>
        </sqf:replace>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- Entries should have IDs -->
  <sch:pattern>
    <sch:rule context="*[contains(@class, ' topic/dlentry ')]">
      <!-- List shouls have an ID check -->
      <sch:assert test="@id" role="warn" sqf:fix="addId addIds">
        Definition list entry should have an ID attribute.
      </sch:assert>
      
      <!-- Quick fix that adds an ID attribute specified by the user -->
      <sqf:fix id="addID">
        <sqf:description>
          <sqf:title>Specify an ID attribute</sqf:title>
        </sqf:description>
        <sqf:user-entry name="newID">
          <sqf:description>
            <sqf:title>Enter ID attribute value:</sqf:title>
          </sqf:description>
        </sqf:user-entry>
        <sqf:add node-type="attribute" target="id" select="$newID"/>
      </sqf:fix>
      
      <sqf:fix id="addId">
        <sqf:description>
          <sqf:title>Add @id to the current definition entry</sqf:title>
          <sqf:p>Add an @id attribute to the current definition entry. The ID is generated from the term definition.</sqf:p>
        </sqf:description>
        
        <!-- Generate an id based on the section title. If there is no title then generate a random id. -->
        <sqf:add target="id" node-type="attribute"
          select="if (exists(dt) and string-length(dt) > 0) 
          then substring(lower-case(replace(replace(normalize-space(string(dt)), '\s', '_'), '[^a-zA-Z0-9_]', '')), 0, 50) 
          else generate-id()"/>
      </sqf:fix>
      
      <sqf:fix id="addIds">
        <sqf:description>
          <sqf:title>Add @id to all definition entries</sqf:title>
          <sqf:p>Add an @id attribute to each drfinition entry from the document. The ID is generated from the term definition.</sqf:p>
        </sqf:description>
        <!-- Generate an id based on the section title. If there is no title then generate a random id. -->
        <sqf:add match="//*[contains(@class, ' topic/dlentry ')][not(@id)]" target="id" node-type="attribute" 
          select="if (exists(dt) and string-length(dt) > 0) 
          then substring(lower-case(replace(replace(normalize-space(string(dt)), '\s', '_'), '[^a-zA-Z0-9_]', '')), 0, 50) 
          else generate-id()"/>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- Add a in prolog keyword before body --> 
  <sch:pattern>
    <sch:rule context="topic">
      <sch:assert test="exists(prolog/metadata/keywords)" sqf:fix="addKeywords" role="warn">
        No keywords are set for the current topic.
      </sch:assert>
      <sqf:fix id="addKeywords">
        <sqf:description>
          <sqf:title>Add keywords for the current topic</sqf:title>
        </sqf:description>
        <sqf:user-entry name="keyword">
          <sqf:description>
            <sqf:title>Keyword value:</sqf:title>
          </sqf:description>
        </sqf:user-entry>
        
        <sqf:add match="body" position="before">
          <prolog>
            <metadata>
              <keywords>
                <indexterm>
                  <sch:value-of select="$keyword"/>
                </indexterm>
              </keywords>
            </metadata>
          </prolog>
        </sqf:add>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- Rules for 'related-links':
    - we want the 'related-links' to contain only one 'linklist'
    - the 'linklist' must have a title
    - if there is a 'link' added directly in a ''related-links', it sould be moved in a 'linklist'
   -->
  <sch:pattern>
    <sch:rule context="related-links/link">
      <sch:assert test="false()" sqf:fix="wrapInLinkList moveInExistingLinkList" role="warn">
        The 'link' element should be added in a 'linklist'</sch:assert>
      
      <!-- Create a new link list -->
      <sqf:fix id="wrapInLinkList" use-when="not(parent::node()/linklist)">
        <sqf:description>
          <sqf:title>Move all the links in a link list</sqf:title>
        </sqf:description>
        <!-- The value for the title element must be specified by the user. -->
        <sch:let name="title" value="'Related Information:'"/>
        <sqf:add node-type="element" target="linklist" position="before">
          <title><xsl:value-of select="$title"/></title>
          <xsl:apply-templates mode="copyExceptClass" select="parent::node()/link"/>
        </sqf:add>
        <sqf:delete match="parent::node()/link"/>
      </sqf:fix>
      
      <!-- Move all the links in the existing link list -->
      <sqf:fix id="moveInExistingLinkList" use-when="parent::node()/linklist">
        <sqf:description>
          <sqf:title>Move all the links in the existing link list</sqf:title>
        </sqf:description>
        <sch:let name="links" value="parent::node()/link"/>
        <sqf:add match="parent::node()/linklist[1]" position="last-child">
          <xsl:apply-templates mode="copyExceptClass" select="$links"/>
        </sqf:add>
        <sqf:delete match="$links"/>
      </sqf:fix>
    </sch:rule>
    
    <sch:rule context="related-links/linklist/title">
      <sch:assert test="text() = 'Related Information:'" sqf:fix="correctTitle" role="warn">
        The title of a linklist must be 'Related Information:'
      </sch:assert>
      
      <sqf:fix id="correctTitle">
        <sqf:description>
          <sqf:title>Set the title to 'Related Information:'</sqf:title>
        </sqf:description>
        <sqf:replace match="text()" select="'Related Information:'"></sqf:replace>
      </sqf:fix>
    </sch:rule>
    
    <sch:rule context="related-links/linklist">
      <!-- The link list should have a title -->
      <sch:assert test="title" sqf:fix="add_title" role="warn">The linklist should have a title</sch:assert>
      
      <!-- Quick fix that adds a title element in a linklist -->
      <sqf:fix id="add_title">
        <sqf:description>
          <sqf:title>Add a title for the linklist</sqf:title>
        </sqf:description>
        <!-- The value for the title element must be specified by the user. -->
        <sch:let name="title" value="'Related Information:'"/>
        <sqf:add node-type="element" position="first-child" target="title" select="$title"/>
      </sqf:fix>
      
      <!-- Only one link list allowed -->
      <sch:report test="following-sibling::linklist" sqf:fix="mergeLinkLists" role="warn">
        Only one link list allowed
      </sch:report>
      
      <!-- Merge flowing link lists into current one -->
      <sqf:fix id="mergeLinkLists">
        <sqf:description>
          <sqf:title>Merge flowing link lists into current one</sqf:title>
        </sqf:description>
        <sqf:add position="last-child">
          <xsl:apply-templates mode="copyExceptClass" select="following-sibling::linklist/link"/>
        </sqf:add>
        <sqf:delete match="following-sibling::linklist"/>
      </sqf:fix>
    </sch:rule>
  </sch:pattern>
  
  <!-- Template used to copy the current node -->
  <xsl:template match="node() | @*" mode="copyExceptClass">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="node() | @*" mode="copyExceptClass"/>
    </xsl:copy>
  </xsl:template>
  <!-- Template used to skip the @class attribute from being copied -->
  <xsl:template match="@class" mode="copyExceptClass"/>
  
  <!-- Template that breaks a text into its composing lines of text -->
  <xsl:function name="oxyF:lineLengthCheck" as="xs:string">
    <xsl:param name="textToBeChecked" as="xs:string"/>
    <xsl:param name="maxLength" as="xs:integer"/>
    <xsl:value-of>
      <xsl:for-each select="tokenize($textToBeChecked, '\n')">
        <xsl:if test="string-length(current()) > $maxLength">
          <xsl:value-of select="concat('line ', position(), ' has ', string-length(current()), ' characters, ') "/>
        </xsl:if>
      </xsl:for-each>
    </xsl:value-of>
  </xsl:function>
</sch:schema>
