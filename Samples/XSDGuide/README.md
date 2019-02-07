# XSD Guide

The XSD Guide is designed to guide an inexperienced developer through the cliffs of XSD development. It is based on Schematron, Schematron QuickFix and XSLT. 

## Prerequirements

The XSD Guide is tested with 

- Oxygen XML Editor v20.1
- Escali Plugin v0.2.0 & Oxygen XML Editor v20.0

## Installation

### Oxygen XML Editor only

1. Please make sure Oxygen XML Editor is installed.
1. Use the addon function of Oxygen (Help > Install new add-ons...)
1. Use the following URL as "update site": [https://raw.githubusercontent.com/octavianN/thePowerOfSQF/master/Samples/XSDGuide/build/extensions.xml](https://raw.githubusercontent.com/octavianN/thePowerOfSQF/master/Samples/XSDGuide/build/extensions.xml)
1. Istall the XSD Guide framework and follow the installation guide.

### Escali Oxygen Plugin

1. Please make sure Oxygen XML Editor is installed.
1. Install the Esali Oxygen Plugin (described [here](https://github.com/schematron-quickfix/escali-package/tree/master/escaliOxygen))
1. Download the source files:
[https://github.com/octavianN/thePowerOfSQF/blob/master/Samples/XSDGuide/build/xsdguide-1.0.0-addon.zip](https://github.com/octavianN/thePowerOfSQF/blob/master/Samples/XSDGuide/build/xsdguide-1.0.0-addon.zip)
1. Extract the zip into any folder (XSD Guide install dir).
1. Go to Oxygen > Window > View > Escali Schematron > Options (gear symbol, in the top right corner).
1. Activate the option "Detect schema by the following rule table"
1. Add a rule or row, by using the add button (plus symbol at the right side)
1. Fill the row:
    1. Schema: Select *XSD guide install dir* > xsdguide-1.0.0/xsd.sch
    1. Match type:  Namespace
    1. Match pattern: `http://www.w3.org/2001/XMLSchema`
    1. Phase: `#ALL` 
    1. Language: `#NULL`
    
## Usage

### Start Oxygen only

1. Go to Oxygen > File > New file...
1. Choose the template *Guided XML Schema without target Namespace*
1. Select your basic XSD design pattern (Venetian Blind or Salami Slice is supported).
1. To use the XSD guide you should be able to execute [QuickFixes with Oxygen](https://www.oxygenxml.com/doc/versions/20.1/ug-editor/glossary/quick-fix.html)

### Start Escali Plugin

1. Go to Oxygen > File > New file...
1. Choose the XML-Schema template
1. Let Oxygen validate the file
1. In the view Escali Schematron the info "The XSD guide is inactive" should be listed and the root element `xs:schema` should be underlined.
1. Execute the QuickFix "Set the XSD guide active" by one of two alternative ways:
    1. Select the info in the Escali Schematron > The view Escali QuickFixes should be poped up > select the radio button of the QuickFix "Set the XSD guide active" > press "Execute QuickFix & validate" button
    1. Set the cursor on the start tag of the root element `xs:schema` > press `crtl` + right-click (or `alt` + `1` > Select the QuickFix "Set the XSD guide active"
1.  After execution and revalidation a new Schematron info should be displayed: "Please select the basic XSD design pattern. Possible patterns are: 'Venetian Blind' or 'Salami Slice'."
1. Execute one of the QuickFix "Choose the Venetian Blind pattern" or "Choos the Salami Slice pattern" depending on what pattern you prefer.

### General usage

Please follow the instructions which are provided by Schematron info messages and execute the provided QuickFixes to create your structure. If more user dependent information is required for one QuickFix, a UserEntry will pop up.

### DTD Syntax

To create content models some UserEntries are expecting "DTD syntax". This refers to the syntax which has become very well known through DTDs (but is also used e.g. by RelaxNG) to describe a content model of an element.

Examples:

```
(a, b?, c*)
```
Meaning: A sequence with a mandatory `a` element, optional followed by a `b` element, optional followed by a unbound sequence of c elements.

Please note that you are free to describe any content model and do not have to respect existing declarations of elements or types. The declaration of missing types or declarations can be done later by other QuickFixes.

#### Extensions of DTD syntax

The multiplier `+`, `*` and `?` are already known in DTDs and are also supported here. To support also a specific number of allowed occurences, the syntax allows also curly brackets as multiplier:

```
(a, b{3:3}, c{5:})
```

Meaning: A sequence with a mandatory `a` element, followed by exact three `b` elements, followed by a unbound sequence, but at least an amount of five c elements.



