import module namespace dba = "org.highwire.hpp.dba-update" at "/reprocessing/lib/lib-dba-update.xqy";

declare namespace hw="org.highwire.hpp";
declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $server as xs:string external;
declare variable $corpus as xs:string external;
declare variable $dry-run as xs:boolean := true();

declare variable $svc-atom as xs:string := '/svc.atom';

declare variable $directory as xs:string := concat('/',$corpus,'/');
declare variable $corpus-atom as xs:string := concat('/',$corpus,'.atom');

if ($corpus eq '') 
then error(xs:QName('bad-corpus'),'corpus must not be nil')
else (),
xdmp:set-request-time-limit(3600),
<report xml:base="{$server}" at="{current-dateTime()}" xmlns:hw="org.highwire.hpp">{
for $f in (
  xdmp:directory($directory,'infinity')/hw:doc[hw:resource-meta[not(@status eq 'deleted')]],
  doc($corpus-atom)/hw:doc
)
let
  $uri := base-uri($f),
  $resource-meta-old := $f/hw:resource-meta,
  $resource-meta-new := element{'hw:resource-meta'}{attribute{'status'}{'deleted'},$resource-meta-old/(@created,@updated),attribute{'deleted'}{current-dateTime()}},
  $delete := $f/*[not(. is $resource-meta-old)]
order by $uri
return
  <node href="{$uri}" deleted="{not($dry-run)}">{
    if ($dry-run)
    then ($resource-meta-old,$resource-meta-new)
    else (
      (for $n in $delete return xdmp:node-delete($n)),
      xdmp:node-replace($resource-meta-old,$resource-meta-new),
      $resource-meta-new
    )
  }</node>,
let
  $corpus-link as element(atom:link)? := doc($svc-atom)/hw:doc/atom:entry/atom:link[@rel eq 'http://schema.highwire.org/Compound#child'][@href eq $corpus-atom]
return
  if (exists($corpus-link))
  then 
    <svc-link deleted="{not($dry-run)}">{
    if ($dry-run)
    then $corpus-link
    else (
      dba:update-metadata($svc-atom),
      xdmp:node-delete($corpus-link),
      $corpus-link
    )
    }</svc-link>
  else ()
}</report>