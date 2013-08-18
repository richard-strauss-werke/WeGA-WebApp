xquery version "3.0";

(:~
 : XQuery module for transforming TEI to XHTML 
 : Elements from the TEI module linking
 :)
module namespace tei2html-transcr="http://xquery.weber-gesamtausgabe.de/modules/tei2html-transcr";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
(:import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";:)

(:declare function tei2html-transcr:addSpan($node as element(tei:addSpan), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-transcr:damage($node as element(tei:damage), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-transcr:subst($node as element(tei:subst), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-transcr:space($node as element(tei:space), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-transcr:supplied($node as element(tei:supplied), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-transcr:handShift($node as element(tei:handShift), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
:)