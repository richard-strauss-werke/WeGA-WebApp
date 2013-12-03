xquery version "3.0";

(:~
 : XQuery module for generating navigation elements 
 : (these will be called by the HTML templates)
 :)
module namespace html-nav="http://xquery.weber-gesamtausgabe.de/modules/html-nav";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

(:~
 : Top navigation for all pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-top-bar-section($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:section) {
    let $html_pixDir := config:get-option('pixDir')
    let $uriTokens := tokenize(xmldb:decode-uri(request:get-uri()), '/')
    let $search := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('search', $lang)), '/'))
    let $index := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('index', $lang)), '/'))
    let $impressum := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('about', $lang)), '/'))
    let $help := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('help', $lang)), '/'))
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
            if (matches($i, 'A\d{6}')) then $i
            else if($lang eq 'en') then replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
            else replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <a href="{html-link:link-to-current-app(string-join(('de', $switchLanguage), '/'))}" title="Diese Seite auf Deutsch"><img src="{html-link:link-to-current-app(string-join(($html_pixDir, 'de.gif'), '/'))}" alt="germanFlag" width="20" height="12"/></a>
        else <a href="{html-link:link-to-current-app(string-join(('en', $switchLanguage), '/'))}" title="This page in english"><img src="{html-link:link-to-current-app(string-join(($html_pixDir, 'gb.gif'), '/'))}" alt="englishFlag" width="20" height="12"/></a>
    return 
    element section {
        attribute class {"top-bar-section"},
        (:if(config:get-option('environment') eq 'development') then attribute class {'dev'}
        else if(config:get-option('environment') eq 'release') then attribute class {'rel'}
        else (),
        <h1><a href="{$index}"><span class="hiddenLink">Carl Maria von Weber Gesamtausgabe</span></a></h1>,:)
        <ul class="left">
            <li class="has-form">
                <form>
                    <div class="row collapse">
                        <div class="small-8 columns">
                            <input type="text"/>
                        </div>
                        <div class="small-4 columns">
                            <a href="#" class="small button search">Search</a>
                        </div>
                    </div>
                </form>
            </li>
        </ul>,
        <ul class="right">
            <li><a href="{$index}">{lang:get-language-string('home',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$impressum}">{lang:get-language-string('about',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$help}">{lang:get-language-string('help',$lang)}</a></li>
            <li class="divider"></li>
            <li>{$switchLanguage}</li>
        </ul>
    }
};

(:~
 : Sub navigation for the index and error pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-digital-edition($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-digital-edition" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{lang:get-language-string('digitalEdition', $lang)}</h3>
        <ul>
            <li><a href="{html-link:link-to-current-app($lang || '/A002068')}">Weber Person</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('correspondence', $lang)), '/'))}">Weber {lang:get-language-string('correspondence', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('diaries', $lang)), '/'))}">Weber {lang:get-language-string('diaries', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('writings', $lang)), '/'))}">Weber {lang:get-language-string('writings', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('works', $lang)), '/'))}">Weber {lang:get-language-string('works', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('indices', $lang)), '/'))}">{lang:get-language-string('indices', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-project-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-project-links" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{lang:get-language-string('aboutTheProject', $lang)}</h3>
        <ul>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('indices',$lang), lang:get-language-string('news',$lang)),'/'))}">{lang:get-language-string('news', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, replace(lang:get-language-string('editorialGuidelines',$lang), '\s', '_')),'/'))}">{lang:get-language-string('editorialGuidelines', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, replace(lang:get-language-string('projectDescription',$lang), '\s', '_')), '/'))}">{lang:get-language-string('projectDescription', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('publications',$lang)), '/'))}">{lang:get-language-string('publications', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('bibliography',$lang)), '/'))}">{lang:get-language-string('bibliography', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('contact',$lang)), '/'))}">{lang:get-language-string('contact', $lang)}</a></li>
        </ul>
    </div>
};

declare function html-nav:page-nav-printed-edition($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-printed-edition" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{lang:get-language-string('printedEdition', $lang)}</h3>
        <ul>
           <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('volumes',$lang)), '/'))}">{lang:get-language-string('volumes', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-dev-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-dev-links" xmlns="http://www.w3.org/1999/xhtml">{
        element h3 {lang:get-language-string('development', $lang)},
        element ul {
            element li {
                element a {
                    attribute href {html-link:link-to-current-app(string-join(($lang, lang:get-language-string('tools', $lang)), '/'))},
                    'Tools'
                }
            }
        }
    }
    </div>
};

declare function html-nav:page-nav-combined($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div class="section-container accordion" data-section="accordion" data-options="one_up: false;" xmlns="http://www.w3.org/1999/xhtml">
        <section class="active">
            <p class="title" data-section-title=""><a href="#">{lang:get-language-string('digitalEdition', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    {html-nav:page-nav-digital-edition($node, $model, $lang)//xhtml:li}
                </ul>
            </div>
        </section>
        <section>
            <p class="title" data-section-title=""><a href="#">{lang:get-language-string('printedEdition', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    {html-nav:page-nav-printed-edition($node, $model, $lang)//xhtml:li}
                </ul>
            </div>
        </section>
        <section>
            <p class="title" data-section-title=""><a href="#">{lang:get-language-string('aboutTheProject', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    {html-nav:page-nav-project-links($node, $model, $lang)//xhtml:li}
                </ul>
            </div>
        </section>
    </div>
};

declare function html-nav:doc2-sub-nav($docID as xs:string, $lang as xs:string) as element(xhtml:dl) {
    let $first-tab-text := 
        if(config:is-letter($docID)) then lang:get-language-string('textOfLetter', $lang)
        else if(config:is-writing($docID)) then lang:get-language-string('textOfDoc', $lang)
        else 'Text'
    return 
        <dl class="sub-nav right" xmlns="http://www.w3.org/1999/xhtml">
            <dt></dt>
            <dd class="active"><a href="#">{$first-tab-text}</a></dd>
            <dd><a href="#">XML</a></dd>
            {
            if(config:is-news($docID)) then ()
            else <dd><a href="#">{lang:get-language-string('facsimile', $lang)}</a></dd>
            }
        </dl>
};

(: muss noch ins doc2.html verschoben werden :)
(:declare function html-nav:print-diaryday($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="print-diaryday" class="content" data-section-content="" xmlns="http://www.w3.org/1999/xhtml">
        <h5>{lang:get-language-string('prevDiaryDay', $lang)}</h5>
            <a href="">21.Januar 1817</a>
            
        <h5>{lang:get-language-string('nextDiaryDay', $lang)}</h5>
        <a href="">23.Januar 1817</a>
    </div>
};:)


declare function html-nav:page-breadcrumb($node as node(), $model as map(*), $docID as xs:string, $lang as xs:string) as element(xhtml:div)? {
     let $current-tab := 
        if(config:is-writing($docID)) then lang:get-language-string('writings', $lang)
        else if(config:is-diary($docID)) then lang:get-language-string('diaries', $lang)
        else if(config:is-work($docID)) then lang:get-language-string('works', $lang)
        else if(config:is-letter($docID)) then lang:get-language-string('correspondence', $lang)
        else ()
     return
        if($current-tab) then
            <div class="row">
                <nav class="breadcrumbs">
                         <a href="http://www.weber-gesamtausgabe.de/de/A002068">Carl Maria von Weber</a>
                         <a>{$current-tab}</a>
                         <a class="current">{$docID}</a>
                </nav>
            </div>
        else ()
};
