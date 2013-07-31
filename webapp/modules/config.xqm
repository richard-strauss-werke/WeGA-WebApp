xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace functx="http://www.functx.com" at "functx.xqm";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:catalogues-collection as xs:string := $config:app-root || '/catalogues';
declare variable $config:options-file as document-node() := doc($config:catalogues-collection || '/options.xml');
declare variable $config:svn-change-history-file as document-node() := doc($config:catalogues-collection || '/svnChangeHistory.xml');
declare variable $config:data-collection-path as xs:string := '/db/apps/WeGA-data';
declare variable $config:tmp as xs:string := $config:app-root || '/tmp';

declare variable $config:isDevelopment as xs:boolean := config:get-option('environment') eq 'development';

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
(:declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};:)

(:~
 :  Returns the requested option value from an option file given by the variable $wega:optionsFile
 :  
 : @author Peter Stadler
 : @param $key the key to look for in the options file
 : @return xs:string the option value as string identified by the key otherwise the empty string
 :)
declare function config:get-option($key as xs:string?) as xs:string {
    let $dic := $config:options-file
    let $item := $dic//id($key)
    return normalize-space($item)
};

(:~
 : Get options from options file
 :
 : @author Peter Stadler
 : @param $key
 : @param $replacements
 : @return xs:string
 :)
declare function config:get-option($key as xs:string?, $replacements as xs:string*) as xs:string {
    let $dic := $config:options-file
    let $item := $dic//id($key)
    let $placeHolders := 
        for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return functx:replace-multi($item,$placeHolders,$replacements)
};

(:~
 : Gets document type by ID
 :
 : @author Peter Stadler
 : @param $id 
 : @return xs:string document type
:)
declare function config:getDoctypeByID($id as xs:string) as xs:string? {
    if(config:isPerson($id)) then 'persons'
    else if(config:isWriting($id)) then 'writings'
    else if(config:isWork($id)) then 'works'
    else if(config:isDiary($id)) then 'diaries'
    else if(config:isLetter($id)) then 'letters'
    else if(config:isNews($id)) then 'news'
    else if(config:isIconography($id)) then 'iconography'
    else if(config:isVar($id)) then 'var'
    else if(config:isBiblio($id)) then 'biblio'
    else ()
};

(:~
 : Checks whether a given id matches the WeGA pattern of person ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isPerson($docID as xs:string) as xs:boolean {
    matches($docID, '^A00\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of iconography ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isIconography($docID as xs:string) as xs:boolean {
    matches($docID, '^A01\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of work ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isWork($docID as xs:string) as xs:boolean {
    matches($docID, '^A02\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of writing ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isWriting($docID as xs:string) as xs:boolean {
    matches($docID, '^A03\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of letter ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isLetter($docID as xs:string) as xs:boolean {
    matches($docID, '^A04\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of news ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isNews($docID as xs:string) as xs:boolean {
    matches($docID, '^A05\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of diary ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isDiary($docID as xs:string) as xs:boolean {
    matches($docID, '^A06\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of var ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isVar($docID as xs:string) as xs:boolean {
    matches($docID, '^A07\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of biblio ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isBiblio($docID as xs:string) as xs:boolean {
    matches($docID, '^A11\d{4}$')
};

(:~
 : Checks whether a given document is from the series "Weber-Studien" published by the WeGA
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:isWeberStudies($doc as document-node()) as xs:boolean {
    $doc//tei:series/tei:title[@level = 's'] = 'Weber-Studien'
};

(:~
 : Checks whether a given string matches the defined types of bibliographic objects
 :
 : @author Peter Stadler
 : @param $string the string to test
 : @return xs:boolean
:)
declare function config:isBiblioType($string as xs:string) as xs:boolean {
    $string = ('mastersthesis', 'inbook', 'online', 'review', 'book', 'misc', 'inproceedings', 'article', 'score', 'incollection', 'phdthesis')
};

(:~
 : Checks the id for well-formedness and returns its collection path. Doesn't check for availability!
 :
 : @author Peter Stadler
 : @param $docID the id of the TEI document
 : @return xs:string the collection path of the document 
:)
declare function config:getCollectionPath($docID as xs:string) as xs:string? {
    let $docType := config:getDoctypeByID($docID)
    return 
        if(exists($docType)) then string-join(($config:data-collection-path, $docType, replace($docID, '\d{2}$', 'xx')), '/') 
        else ()
};

(:~
 : returns whether eXist-DB was updated after a given dateTime. 
 : The function tries to cast the given $dateTime as xs:dateTime and returns true() on default if $dateTime is not castable.
 :
 : @author Peter Stadler
 : @param $dateTime the date to check
 : @return xs:boolean
:)
declare function config:eXistDbWasUpdatedAfterwards($dateTime as xs:dateTime?) as xs:boolean {
    if($dateTime castable as xs:dateTime) then config:getDateTimeOfLastDBUpdate() gt ($dateTime cast as xs:dateTime)
    else true()
};

(:~
 : retrieves the dateTime of last eXist-db update by checking svnChangeHistoryFile
 :
 : @author Peter Stadler
 : @return xs:dateTime
:)
declare function config:getDateTimeOfLastDBUpdate() as xs:dateTime? {
    xmldb:last-modified($config:catalogues-collection, 'svnChangeHistory.xml')
};

(:~
 : Returns the current head revision of the database as given by the 'svnChangeHistoryFile'
 :
 : @author Peter Stadler
 : @return xs:int
:)
declare function config:getCurrentSvnRev() as xs:int? {
    let $myNode := $config:svn-change-history-file/dictionary/@head
    return 
        if($myNode castable as xs:int) then $myNode cast as xs:int
        else ()
};