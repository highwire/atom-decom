declare namespace hw="org.highwire.hpp";

declare variable $server as xs:string external;
declare variable $corpus as xs:string external;

declare variable $directory as xs:string := concat('/',$corpus,'/');
declare variable $corpus-atom as xs:string := concat('/',$corpus,'.atom');

<report xml:base="{$server}" at="{current-dateTime()}">{
for $f in (
  xdmp:directory($directory,'infinity')/hw:doc[hw:resource-meta[@status eq 'deleted']],
  doc($corpus-atom)/hw:doc[hw:resource-meta[@status eq 'deleted']]
)
let $uri := base-uri($f)
order by $uri
return
 <tombstone href="{$uri}"/>

}</report>