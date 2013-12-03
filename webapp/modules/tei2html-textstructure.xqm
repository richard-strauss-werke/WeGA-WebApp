xquery version "3.0";

(:~
 : XQuery module for transforming TEI to XHTML 
 : Elements from the TEI module linking
 :)
module namespace tei2html-textstructure="http://xquery.weber-gesamtausgabe.de/modules/tei2html-textstructure";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace tei2html="http://xquery.weber-gesamtausgabe.de/modules/tei2html" at "tei2html.xqm";
(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
(:import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";:)


declare function tei2html-textstructure:body($node as element(tei:body), $lang as xs:string) {
    tei2html:process($node/node(), $lang)
};

declare function tei2html-textstructure:div($node as element(tei:div), $lang as xs:string)  as element(xhtml:div) {
    element xhtml:div {
        tei2html:process($node/node(), $lang)
    }
};

(:
declare function tei2html-textstructure:closer($node as element(tei:closer), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:dateline($node as element(tei:dateline), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-textstructure:opener($node as element(tei:opener), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:salute($node as element(tei:salute), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:signed($node as element(tei:signed), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:postscript($node as element(tei:postscript), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:floatingText($node as element(tei:floatingText), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-textstructure:byline($node as element(tei:byline), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
:)
