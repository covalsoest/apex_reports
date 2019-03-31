create or replace PACKAGE APEXDEMO IS
/*********************************************************************
Purpose  API Routines for COVAL APEX DEMO application
Author   W. van Valenberg (©Coval, 2018)
Date     10-SEP-2018
Remarks
*********************************************************************/

--
-- public cursors and variables
--

procedure p003_render_params -- report selection region
( p_mde_id  in  number       -- report id
) ;

procedure run_report
( p_json_text          in         clob
, p_url                out        varchar2
, p_error              out        boolean
, p_error_message      out        varchar2
, p_debug              in boolean default false
) ;

end apexdemo;
/


create or replace PACKAGE body APEXDEMO IS
/*********************************************************************
Purpose  API Routines for COVAL APEX DEMO application
Author   W. van Valenberg (©Coval, 2018)
Date     10-SEP-2018
Remarks
*********************************************************************/

--
-- globals (to the body procedures) cursors and variables
--

  -- change where needed
  gb_reports_server      varchar2(240)  := 'http://localhost:7778/reports/rwservlet?server=rep_www_asfr10g102' ;
  gb_reports_server_soap varchar2(240)  := 'http://localhost:7778/reports/rwwebservice'                        ;
  gb_soap_version        varchar2(240)  := 'SOAP10G'             ;
  gb_login_string        varchar2(240)  := 'headstart/pwd@orcl'  ;
  gb_output_dir          varchar2(240)  := '/tmp'                ;
  --
  gb_sep                 varchar2(1)    := ' '                   ; -- RWSERVLET chr(38) ;
  gb_sqlerrm             varchar2(2000)                          ;

function convert_html ( p_clob in clob) return clob is  -- private function
  l_clob clob;
  l_amp  varchar2(1) default chr(38) ;
begin
  l_clob := replace(p_clob, l_amp || 'lt;'  , '<' );
  l_clob := replace(l_clob, l_amp || 'gt;'  , '>' );
  l_clob := replace(l_clob, l_amp || 'apos;', chr(39) ); -- single quote
  l_clob := replace(l_clob, l_amp || 'quot;', chr(34) ); -- double quote
  return ( l_clob );
end convert_html;


function convert_string ( p_in in varchar2) return varchar2 is  -- private function
  l_out  varchar2(4000);
  l_amp  varchar2(1) default chr(38) ;
begin
  l_out := replace(p_in , l_amp || 'lt;'  , '<' );
  l_out := replace(l_out, l_amp || 'gt;'  , '>' );
  l_out := replace(l_out, l_amp || 'apos;', chr(39) ); -- single quote
  l_out := replace(l_out, l_amp || 'quot;', chr(34) ); -- double quote
  return ( l_out );
end convert_string;


procedure p003_render_region_start is
  l_long varchar2(4000);
begin
  l_long := q'[
<div class="row">
  <div class="col col-12 apex-col-auto">
    <div class="t-Region t-Region--scrollBody ltop3_par_0" id="p3_params">
      <div class="t-Region-header">
        <div class="t-Region-headerItems t-Region-headerItems--title">
          <span class="t-Region-headerIcon"><span class="t-Icon " aria-hidden="true"></span></span>
          <h2 class="t-Region-title" id="p3_params_heading">Parameters</h2>
        </div>
      </div>
      <div class="t-Region-bodyWrap">
        <div class="t-Region-buttons t-Region-buttons--top">
          <div class="t-Region-buttons-left"></div>
          <div class="t-Region-buttons-right"></div>
        </div>
        <div class="t-Region-body">
          <div id="report_p3_par_catch">
            <div class="t-Report t-Report--altRowsDefault t-Report--rowHighlight ltop3_par_1"
              id="report_p3_params" data-region-id="p3_params">
              <div class="t-Report-wrap">
                <table class="t-Report-pagination" role="presentation">
                  <tr>
                    <td></td>
                  </tr>
                </table>
                <div class="t-Report-tableWrap">
                  <table class="t-Report-report" summary="Parameters">
                    <thead>
                      <tr>
                        <th class="t-Report-colHead u-color-29-bg" id="PROMPT">Prompt</th>
                        <th class="t-Report-colHead u-color-29-bg" id="MODULE">Module</th>
                        <th class="t-Report-colHead u-color-29-bg" id="HINT">Help</th>
                      </tr>
                    </thead>
                    <tbody>
]';
  sys.htp.prn(l_long);
end p003_render_region_start;

procedure p003_render_region_end is
  l_long varchar2(4000);
begin
  l_long := q'[
                    </tbody>
                  </table>
                </div>
                <div class="t-Report-links"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
]';
  sys.htp.prn(l_long);
end p003_render_region_end;


procedure p003_render_params -- report selection region
( p_mde_id  in  number
) is

/* the LOV query definition for APEX items cannot be used because the LOV of QMS0012F has a result of id, description
   and the LOV query expects description, id.
   Therefor we use a record type to retrieve the values of the LOV query of QMS
   p_list_values
   List of static values separated by commas. Displays values and returns values that are separated by semicolons.
   Example: 'Yes;Y,No;N'
*/

  l_long           varchar2(32767)                   ;
  i                number default 0                  ;
  l_list_values    varchar2(32767)                   ;
  l_default_value  qms_mde_params.default_value%type ;
  
  type r_lov is record
  ( code        varchar2(255)
  , description varchar2(255)
  ) ;
  type t_lov is table of r_lov;
  l_lov t_lov;
  
begin

  p003_render_region_start;
  
  for r in ( select mpm.mde_id
             ,      mpm.mpm_subtype
             ,      decode(mpm.mpm_subtype
                    , 'SYS', 'u-hot'
                    , 'u-normal'
                    ) class
             ,      mpm.name
             ,      mpm.data_type
             ,      mpm.ind_mandatory
             ,      decode(mpm.ind_mandatory
                    , 'Y', 'required'
                    , 'optional'
                    ) class_mandatory
             ,      mpm.ind_uppercase
             ,      mpm.prompt
             ,      mpm.plength
             ,      mpm.default_value
             ,      mpm.default_description
             ,      mpm.hint_text
             ,      mpm.lov_query
             ,      mpm.lov_multi_select
             from   qms_mde_params           mpm
             where  mpm.mde_id             = p_mde_id
               and  mpm.name         not in ('SERVER','ORACLE_SHUTDOWN')
             order by
                    mpm.mpm_subtype desc
             ,      mpm.display_seqno
           )
  loop
  
    i := i + 1;
    
    sys.htp.prn('<tr>');
    -- prompt
    sys.htp.prn('<td class="t-Report-cell"><span class="prompt '||r.class||'-text '||r.class_mandatory||'">');
    sys.htp.prn(r.prompt);
    sys.htp.prn('</span></td>');
    -- value
    sys.htp.prn('<td class="t-Report-cell"><span class="val '||r.class||'-text '||r.class_mandatory||'">');
      
    l_default_value := r.default_value;

    if r.lov_query is not null
    then
      begin
        execute immediate r.lov_query
        bulk collect
        into    l_lov
        ;
      exception when others then
        -- log error SQLERRM
        raise_application_error(-20001,'Error in dynamic LOV query');
      end;
      
      -- p_list_values
      -- Example: 'Yes;Y,No;N'
      for j in 1 .. l_lov.count
      loop
        l_lov(j).description := replace(l_lov(j).description, ';');
        l_lov(j).description := replace(l_lov(j).description, ',', ' ');
        if j = 1
        then
          l_list_values := l_lov(j).description || ';' || l_lov(j).code ;
        else
          l_list_values := substr( l_list_values || ',' ||
                                   l_lov(j).description || ';' || l_lov(j).code
                                 , 1, 4000) ;
        end if;
      end loop;
    end if;
    
    if r.lov_query is not null and
       r.lov_multi_select = 'N'
    then -- select list
      sys.htp.prn(apex_item.select_list( p_idx         => 1
                                       , p_list_values => l_list_values
                                       , p_attributes  => 'data-name="'      || r.name          || '"; '||
                                                          'data-uppercase="' || r.ind_uppercase || '"; '||
                                                          'data-required="'  || r.ind_mandatory || '"'
                                       , p_value       => l_default_value
                                       , p_show_null   => 'YES'
                                       , p_null_text   => '-- Select '|| r.prompt ||' --'
                                       )
                 );
    elsif r.lov_query is not null and
          r.lov_multi_select = 'Y'
    then -- multiple select list
      sys.htp.prn(apex_item.select_list( p_idx         => 1
                                       , p_list_values => l_list_values
                                       , p_value       => null -- l_default_value, does not work, have not figured out yet
                                       , p_attributes  => 'multiple=true; size=7; '||
                                                          'data-name="'      || r.name          || '"; '||
                                                          'data-uppercase="' || r.ind_uppercase || '"; '||
                                                          'data-required="'  || r.ind_mandatory || '"'
                                       , p_show_null   => 'YES'
                                       , p_null_text   => '-- Select '|| r.prompt ||' --'
                                       )
                 );
    else
      sys.htp.prn(apex_item.text( p_idx         => 1
                                , p_item_id     => r.name
                                , p_item_label  => r.name
                                , p_attributes  => 'data-name="'      || r.name          || '" '||
                                                   'data-uppercase="' || r.ind_uppercase || '" '||
                                                   'data-required="'  || r.ind_mandatory || '"'
                                , p_value       => l_default_value
                                )
                 );
    end if;
      
    sys.htp.prn('</span></td>');
    if r.hint_text is not null
    then
      sys.htp.prn('<td class="t-Report-cell"><span class="hint '||r.class||'-text">'||r.hint_text||'</span></td>');
    else
      sys.htp.prn('<td class="t-Report-cell"></td>');
    end if;
    sys.htp.prn('</tr>');
  end loop;
  
  -- close table and region
  p003_render_region_end;
  
end p003_render_params;


procedure compose_parameterstring
( p_json_text        in clob
, p_paramlist        out        varchar2
, p_error            out        boolean
, p_error_message    out        varchar2
, p_debug            in         boolean  default false
) is

  type               t_params is table of varchar2(240) index by varchar2(240);
  a_params           t_params                ;

  l_json_text        apex_json.t_values      ;
  l_paramlist        varchar2(4000)          ;
  l_key              varchar2(240)           ;
  l_value            varchar2(240)           ;
  l_error_message    varchar2(4000)          ;
  l_error            boolean default false   ;

begin

  for r in (select key,value,required,uppercase
            from xmltable(
                           '/json/row'
                           passing apex_json.to_xmltype(p_json_text)
                           columns
                             key       varchar2(240) path '/row/key',
                             value     varchar2(240) path '/row/value',
                             required  varchar2(240) path '/row/required',
                             uppercase varchar2(240) path '/row/uppercase'
                         )
           )
  loop
  
    l_key   := upper(r.key)          ;
    l_value := nvl(r.value,'%NULL%') ;
    
    if r.required = 'Y' and upper(l_value) = '%NULL%'
    then -- no value for required field
      l_error_message := nvl(l_error_message, to_char(null)) || 'Field '||l_key || ' must have some value. ';
      l_error         := true;
    elsif upper(l_value) != '%NULL%' -- field has value
    then
      if l_key = 'DESTYPE'
      then
        if upper(l_value) in ('SCREEN', 'PREVIEW', 'PRINTER')
        then -- correct destination type
          l_value := 'CACHE';
        end if;
      end if;

      if r.uppercase = 'Y'
      then
        a_params(l_key) := upper(l_value);
      else
        a_params(l_key) := l_value;
      end if;
      
    end if;
  end loop;

  -- check value of destination in case of file/mail
  if a_params.exists('DESTYPE')   and
     a_params('DESTYPE') in ('FILE','MAIL')
  then
    if not a_params.exists('DESNAME')
    then
      l_error_message     := nvl(l_error_message, to_char(null)) || 'Destination must have some value. ';
      l_error             := true;
    elsif a_params('DESTYPE') = 'FILE'
    then
      a_params('DESNAME') := gb_output_dir || a_params('DESNAME');
    end if;
  end if;

  -- compose parameter string by looping through array
  l_key := a_params.first;
  while (l_key is not null)
  loop
    if l_paramlist is null
    then
      l_paramlist := lower(l_key) || '=' || convert_string(a_params(l_key)) ;
    else
      l_paramlist := l_paramlist || gb_sep || lower(l_key) || '=' || convert_string(a_params(l_key)) ;
    end if;
    l_key := a_params.next(l_key);
  end loop;

  -- added user credentials
  if l_paramlist is null
  then
    l_paramlist := 'userid=' || convert_string(gb_login_string) ;
  else
    l_paramlist := l_paramlist || gb_sep || 'userid=' || convert_string(gb_login_string) ;
  end if;

  -- return values
  p_error           := l_error         ;
  if l_error
  then
    p_error_message := l_error_message ;
  else
    p_paramlist     := l_paramlist     ;
  end if;

end compose_parameterstring;


procedure run_report_soap
( p_paramlist      in   varchar2
, p_error          out  boolean
, p_error_message  out  varchar2
, p_debug          in   boolean default false
, p_response_xml   out  xmltype
) is

  l_soap_req        varchar2(30000) ;
  l_soap_resp       varchar2(30000) ;
  l_http_req        utl_http.req    ;
  l_http_resp       utl_http.resp   ;

  l_response_xml    xmltype         ;
  l_response_clob   clob            ;

begin
  -- initialize
  p_error           := false ;
  p_error_message   := null  ;

  if gb_soap_version = 'SOAP10G'
  then
    l_soap_req := q'[
 <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:oracle-reports-rwclient-RWWebService">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:runJob soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <param0 xsi:type="xsd:string">#PARAM#</param0>
         <param1 xsi:type="xsd:boolean">true</param1>
      </urn:runJob>
   </soapenv:Body>
 </soapenv:Envelope>
 ]' ;
  else -- SOAP 12c
    l_soap_req := q'[
 <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:rwc="http://oracle.reports/rwclient/">
   <soapenv:Header/>
   <soapenv:Body>
      <rwc:runJob>
         <!--Optional:-->
         <arg0>#PARAM#</arg0>
         <arg1>true</arg1>
      </rwc:runJob>
   </soapenv:Body>
 </soapenv:Envelope>
 ]';
  end if; -- g_soap_version

  -- substitute param0 value with p_paramlist
  l_soap_req := replace(l_soap_req, '#PARAM#', p_paramlist);

  -- start http request
  utl_http.set_response_error_check(true);
  l_http_req := utl_http.begin_request ( url    => gb_reports_server_soap
                                       , method => 'POST'
                                       , http_version => 'HTTP/1.1'
                                       ) ;
  -- set headers
  utl_http.set_header(l_http_req, 'User-Agent', 'Mozilla/4.0');
  utl_http.set_header(l_http_req, 'Content-Type', 'text/xml;charset=UTF-8'); -- since we are dealing with plain text in XML documents
  utl_http.set_header(l_http_req, 'Content-Length', length(l_soap_req));
  utl_http.set_header(l_http_req, 'SOAPAction', ''); -- required to specify this is a SOAP communication
  utl_http.write_text(l_http_req, l_soap_req);

  -- get http response
  l_http_resp := utl_http.get_response(l_http_req);

  if l_http_resp.status_code = 200
  then
    begin
      utl_http.read_text   (l_http_resp, l_response_clob);
      utl_http.end_response(l_http_resp );
    exception
      when utl_http.end_of_body then
        utl_http.end_response(l_http_resp);
      when others then
        gb_sqlerrm      := sqlerrm;
        p_error         := true;
        if gb_sqlerrm is null
        then
          p_error_message := l_http_resp.status_code ||' '|| l_http_resp.reason_phrase ;
        else
          p_error_message := substr(gb_sqlerrm, 1, 4000);
        end if;
        utl_http.end_response( l_http_resp);
    end;
  else -- l_http_resp.status_code != 200
    p_error         := true;
    if gb_sqlerrm is null
    then
      p_error_message := l_http_resp.status_code ||' '|| l_http_resp.reason_phrase ;
    else
      p_error_message := substr(gb_sqlerrm, 1, 4000);
    end if;
    utl_http.end_response( l_http_resp);
  end if;

  -- convert clob response into xml object
  begin
    l_response_xml := XMLType( l_response_clob );
  exception when others then
    gb_sqlerrm      := sqlerrm;
    p_error         := true;
    p_error_message := substr(gb_sqlerrm, 1, 4000);
  end;

  -- the actual response is the child of the "soap:Body" element
  l_response_clob := l_response_xml.extract('/soap:Envelope/soap:Body/*'
                     , 'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"').getClobVal;

  -- now process ns1 content with CDATA content
  l_response_xml:= XMLType(l_response_clob);

  if l_response_xml.existsnode('//return/text()') = 1
  then
    l_response_clob := convert_html(l_response_xml.extract('//return/text()').getClobVal);
    p_response_xml  := XMLType(l_response_clob);
  end if;

exception when others then
  gb_sqlerrm       := sqlerrm;
  p_error          := true;
  p_error_message  := substr(gb_sqlerrm, 1, 4000);

end run_report_soap;


procedure run_report
( p_json_text          in         clob
, p_url                out        varchar2
, p_error              out        boolean
, p_error_message      out        varchar2
, p_debug              in boolean default false
)
is
  l_jobid           number default null  ;
  l_response_xml    xmltype              ;
  l_error_message   varchar2(4000)       ;
  l_error           boolean              ;
  l_paramlist       varchar2(4000)       ;  

  l_rwservlet_url1  varchar2(240)        ;
  l_rwservlet_url2  varchar2(240)        ;
  
begin

  -- fetch parameter string, including login from json array
  compose_parameterstring
  ( p_json_text        => p_json_text
  , p_paramlist        => l_paramlist
  , p_error            => l_error
  , p_error_message    => l_error_message
  , p_debug            => p_debug
  ) ;

  if not l_error
  then
    run_report_soap      ( p_paramlist      => l_paramlist
                         , p_debug          => p_debug
                         , p_error          => l_error
                         , p_error_message  => l_error_message
                         , p_response_xml   => l_response_xml
                         ) ;

    if not l_error and regexp_like(l_paramlist,'CACHE','i')
    then
      select extract(l_response_xml, 'serverQueues/job/@id').getNumberVal()
      into   l_jobid
      from   dual
      ;
      if l_jobid is not null
      then
        l_rwservlet_url1 := substr(gb_reports_server, 1, instr(gb_reports_server, '?') - 1)          ;
        l_rwservlet_url2 := substr(gb_reports_server, instr(gb_reports_server, '?') )                ;
        p_url            := l_rwservlet_url1 || '/getjobid' || l_jobid || l_rwservlet_url2           ;
      else
        select extract(l_response_xml, 'serverQueues/error/@message').getStringVal()
        into   l_error_message
        from   dual
        ;
        l_error            := true;
        if l_error_message is null
        then
          l_error_message  := 'An error occurred. Check your input parameters or contact administator';
        end if;
      end if;
    end if; -- error during run_report
  else -- error during compose parameterstring
    -- log error
    null;
  end if;

  p_error           := l_error         ;
  p_error_message   := l_error_message ;

end run_report;

end apexdemo;
/

