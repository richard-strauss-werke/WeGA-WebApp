xquery version "3.0";

(:~
 : XQuery module for generating navigation elements 
 : (these will be called by the HTML templates)
 :)
module namespace html-nav="http://xquery.weber-gesamtausgabe.de/modules/html-nav";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace templates="http://exist-db.org/xquery/templates";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
(:import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";:)
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

(:~
 : Top navigation for all pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-top-bar-section($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:section) {
    let $html_pixDir := config:get-option('pixDir')
    let $app-root := request:get-attribute("$exist:controller")
    let $uriTokens := tokenize(xmldb:decode-uri(request:get-uri()), '/')
    let $search := string-join(($app-root, $lang, core:getLanguageString('search', $lang)), '/')
    let $index := string-join(($app-root, $lang, core:getLanguageString('index', $lang)), '/')
    let $impressum := string-join(($app-root, $lang, core:getLanguageString('about', $lang)), '/')
    let $help := string-join(($app-root, $lang, core:getLanguageString('help', $lang)), '/')
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
        if (matches($i, 'A\d{6}'))
            then $i
            else if($lang eq 'en') 
                then replace(core:translateLanguageString(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
                else replace(core:translateLanguageString(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <a href="{string-join(($app-root, 'de', $switchLanguage), '/')}" title="Diese Seite auf Deutsch"><img src="{string-join(($app-root, $html_pixDir, 'de.gif'), '/')}" alt="germanFlag" width="20" height="12"/></a>
        else <a href="{string-join(($app-root, 'en', $switchLanguage), '/')}" title="This page in english"><img src="{string-join(($app-root, $html_pixDir, 'gb.gif'), '/')}" alt="englishFlag" width="20" height="12"/></a>
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
                            <a href="#" class="small button">Search</a>
                        </div>
                    </div>
                </form>
            </li>
        </ul>,
        <ul class="right">
            <li><a href="{$index}">{core:getLanguageString('home',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$impressum}">{core:getLanguageString('about',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$help}">{core:getLanguageString('help',$lang)}</a></li>
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
        <h3>{core:getLanguageString('digitalEdition', $lang)}</h3>
        <ul>
            <li><a href="{$config:app-root || '/A002068'}">Weber Person</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('correspondence', $lang)), '/')}">Weber {core:getLanguageString('correspondence', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('diaries', $lang)), '/')}">Weber {core:getLanguageString('diaries', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('writings', $lang)), '/')}">Weber {core:getLanguageString('writings', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('works', $lang)), '/')}">Weber {core:getLanguageString('works', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices', $lang)), '/')}">{core:getLanguageString('indices', $lang)}</a></li>
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
        <h3>{core:getLanguageString('aboutTheProject', $lang)}</h3>
        <ul>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices',$lang), core:getLanguageString('news',$lang)),'/')}">{core:getLanguageString('news', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('editorialGuidelines',$lang), '\s', '_')),'/')}">{core:getLanguageString('editorialGuidelines', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('projectDescription',$lang), '\s', '_')), '/')}">{core:getLanguageString('projectDescription', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('publications',$lang)), '/')}">{core:getLanguageString('publications', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('bibliography',$lang)), '/')}">{core:getLanguageString('bibliography', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('contact',$lang)), '/')}">{core:getLanguageString('contact', $lang)}</a></li>
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
        element h3 {core:getLanguageString('development', $lang)},
        element ul {
            element li {
                element a {
                    attribute href {string-join(($config:app-root, $lang, core:getLanguageString('tools', $lang)), '/')},
                    'Tools'
                }
            }
        }
    }
    </div>
};

declare function html-nav:page-nav-combined($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div class="section-container accordion" data-section="" data-options="one_up: false;" xmlns="http://www.w3.org/1999/xhtml">
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{core:getLanguageString('digitalEdition', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    <li><a href="{$config:app-root || '/A002068'}">Weber Person</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('correspondence', $lang)), '/')}">Weber {core:getLanguageString('correspondence', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('diaries', $lang)), '/')}">Weber {core:getLanguageString('diaries', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('writings', $lang)), '/')}">Weber {core:getLanguageString('writings', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('works', $lang)), '/')}">Weber {core:getLanguageString('works', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices', $lang)), '/')}">{core:getLanguageString('indices', $lang)}</a></li>
                </ul>
            </div>
        </section>
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{core:getLanguageString('aboutTheProject', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices',$lang), core:getLanguageString('news',$lang)),'/')}">{core:getLanguageString('news', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('editorialGuidelines',$lang), '\s', '_')),'/')}">{core:getLanguageString('editorialGuidelines', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('projectDescription',$lang), '\s', '_')), '/')}">{core:getLanguageString('projectDescription', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('bibliography',$lang)), '/')}">{core:getLanguageString('bibliography', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('publications',$lang)), '/')}">{core:getLanguageString('publications', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('contact',$lang)), '/')}">{core:getLanguageString('contact', $lang)}</a></li>
                </ul>
            </div>
        </section>
    </div>
};
