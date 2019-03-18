# svg-transform
This repository contains:
  - [clean_svg.xsl](clean_svg.xsl) template to remove useless elements from svg files, especially elements added by Inkscape.
  - [resize_svg.xsl](resize_svg.xsl) template to resize one or multiple svg files with various input units (including percentage). This template imports clean_svg.xsl, which must be placed in the same folder (or update the link).
  - [clean_svg.xml](clean_svg.xml) and [resize_svg.xml](resize_svg.xml) to integrate the XSLT templates as custom refactoring operations in Oxygen XML.
