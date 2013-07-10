<%@ page import="rundeck.Execution; com.dtolabs.rundeck.server.authorization.AuthConstants" %>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta name="tabpage" content="jobs"/>
    <meta name="layout" content="base" />
    <title><g:message code="main.app.name"/> - <g:if test="${null==execution?.dateCompleted}">Now Running - </g:if><g:if test="${scheduledExecution}">${scheduledExecution?.jobName.encodeAsHTML()} :  </g:if><g:else>Transient <g:message code="domain.ScheduledExecution.title"/> : </g:else> Execution at <g:relativeDate atDate="${execution.dateStarted}" /> by ${execution.user}</title>
    <g:set var="followmode" value="${params.mode in ['browse','tail','node']?params.mode:null==execution?.dateCompleted?'tail':'browse'}"/>
      <g:set var="authKeys" value="${[AuthConstants.ACTION_KILL, AuthConstants.ACTION_READ,AuthConstants.ACTION_CREATE,AuthConstants.ACTION_RUN]}"/>
      <g:set var="authChecks" value="${[:]}"/>
      <g:each in="${authKeys}" var="actionName">
      <g:if test="${execution.scheduledExecution}">
          <%-- set auth values --%>
          %{
              authChecks[actionName]=auth.jobAllowedTest(job:execution.scheduledExecution,action: actionName)
          }%
      </g:if>
      <g:else>
          %{
              authChecks[actionName] = auth.adhocAllowedTest(action: actionName)
          }%
      </g:else>
      </g:each>
      <g:set var="adhocRunAllowed" value="${auth.adhocAllowedTest(action: AuthConstants.ACTION_RUN)}"/>

      <g:set var="defaultLastLines" value="${grailsApplication.config.rundeck.gui.execution.tail.lines.default}"/>
      <g:set var="maxLastLines" value="${grailsApplication.config.rundeck.gui.execution.tail.lines.max}"/>
      <g:javascript src="executionControl.js?v=${grailsApplication.metadata['app.version']}"/>
      <g:javascript library="prototype/effects"/>
      <g:javascript>
        <g:if test="${scheduledExecution}">
        /** START history
         *
         */
        function loadHistory(){
            new Ajax.Updater('histcontent',"${createLink(controller:'reports',action:'eventsFragment')}",{
                parameters:{compact:true,nofilters:true,jobIdFilter:'${scheduledExecution.id}'},
                evalScripts:true,
                onComplete: function(transport) {
                    if (transport.request.success()) {
                        Element.show('histcontent');
                    }
                }
            });
        }
        </g:if>
        var followControl = new FollowControl('${execution?.id}','commandPerform',{
            appLinks:appLinks,
            iconUrl: "${resource(dir: 'images', file: 'icon-small')}",
            smallIconUrl: "${resource(dir: 'images', file: 'icon-small')}",
            extraParams:"<%="true" == params.disableMarkdown ? '&disableMarkdown=true' : ''%>&markdown=${params.markdown}",
            lastlines: ${params.lastlines ? params.lastlines : defaultLastLines},
            maxLastLines: ${maxLastLines},
            collapseCtx: {value:${null == execution?.dateCompleted },changed:false},
            showFinalLine: {value:false,changed:false},
            tailmode: ${followmode == 'tail'},
            browsemode: ${followmode == 'browse'},
            nodemode: ${followmode == 'node'},
            execData: {node:"${session.Framework.getFrameworkNodeHostname()}"},
            <g:if test="${authChecks[AuthConstants.ACTION_KILL]}">
            killjobhtml: '<span class="action button textbtn" onclick="followControl.docancel();">Kill <g:message code="domain.ScheduledExecution.title"/> <img src="${resource(dir: 'images', file: 'icon-tiny-removex.png')}" alt="Kill" width="12px" height="12px"/></span>',
            </g:if>
            <g:if test="${!authChecks[AuthConstants.ACTION_KILL]}">
            killjobhtml: "",
            </g:if>
            totalDuration : 0 + ${scheduledExecution?.totalTime ? scheduledExecution.totalTime : -1},
            totalCount: 0 + ${scheduledExecution?.execCount ? scheduledExecution.execCount : -1}
            <g:if test="${scheduledExecution}">
            , onComplete:loadHistory
            </g:if>
        });


        function init() {
            followControl.beginFollowingOutput('${execution?.id}');
            <g:if test="${!(grailsApplication.config.rundeck?.gui?.enableJobHoverInfo in ['false', false])}">
            $$('.obs_bubblepopup').each(function(e) {
                new BubbleController(e,null,{offx:-14,offy:null}).startObserving();
            });
            </g:if>
        }

        Event.observe(window, 'load', init);

      </g:javascript>
      <style type="text/css">

        #log{
            margin-bottom:20px;
        }
      </style>
  </head>

  <body>
    <div class="pageTop extra">
        <div class="jobHead">
            <table cellspacing="0" cellpadding="0" width="100%">
                <tr>
                    <td  style="vertical-align: top;">
                        <div class="jobInfo">
                        <g:render template="/scheduledExecution/showExecutionHead"
                                  model="[scheduledExecution: scheduledExecution, execution: execution, followparams: [mode: followmode, lastlines: params.lastlines]]"/>
                        <span class="executioncontrol">

                        <g:if test="${null == execution.dateCompleted}">
                            <g:if test="${authChecks[AuthConstants.ACTION_KILL]}">
                                <span id="cancelresult" style="margin-left:10px">
                                    <span class="action button textbtn"
                                          onclick="followControl.docancel();">Kill <g:message
                                            code="domain.ScheduledExecution.title"/> <img
                                            src="${resource(dir: 'images', file: 'icon-tiny-removex.png')}" alt="Kill"
                                            width="12px" height="12px"/></span>
                                </span>
                            </g:if>
                        </g:if>

                        <span id="execRetry"
                              style="${wdgt.styleVisible(if: null != execution.dateCompleted && null != execution.failedNodeList)}; margin-right:10px;">
                            <g:if test="${scheduledExecution}">
                                <g:if test="${authChecks[AuthConstants.ACTION_RUN]}">
                                    <g:link controller="scheduledExecution" action="execute"
                                            id="${scheduledExecution.extid}"
                                            params="${[retryFailedExecId: execution.id]}"
                                            title="Run Job on the failed nodes"
                                            class="action button" style="margin-left:10px">
                                        <img src="${resource(dir: 'images', file: 'icon-small-run.png')}" alt="run"
                                             width="16px" height="16px"/>
                                        Retry Failed Nodes  &hellip;
                                    </g:link>
                                </g:if>
                            </g:if>
                            <g:else>
                                <g:if test="${auth.resourceAllowedTest(kind: 'job', action: [AuthConstants.ACTION_CREATE]) || adhocRunAllowed}">
                                    <g:link controller="scheduledExecution" action="createFromExecution"
                                            params="${[executionId: execution.id, failedNodes: true]}"
                                            class="action button"
                                            title="Retry on the failed nodes&hellip;" style="margin-left:10px">
                                        <img src="${resource(dir: 'images', file: 'icon-small-run.png')}" alt="run"
                                             width="16px" height="16px"/>
                                        Retry Failed Nodes &hellip;
                                    </g:link>
                                </g:if>
                            </g:else>
                        </span>
                        <span id="execRerun" style="${wdgt.styleVisible(if: null != execution.dateCompleted)}">
                            <g:if test="${scheduledExecution}">
                                <g:if test="${authChecks[AuthConstants.ACTION_RUN]}">
                                    &nbsp;
                                    <g:link controller="scheduledExecution"
                                            action="execute"
                                            id="${scheduledExecution.extid}"
                                            params="${[retryExecId: execution.id]}"
                                            class="action button"
                                            title="Run this Job Again with the same options">
                                        <g:img file="icon-small-run.png" alt="run" width="16px" height="16px"/>
                                        Run Again &hellip;
                                    </g:link>
                                </g:if>
                            </g:if>
                            <g:else>
                                <g:if test="${auth.resourceAllowedTest(kind: 'job', action: [AuthConstants.ACTION_CREATE]) || adhocRunAllowed}">
                                    <g:if test="${!scheduledExecution || scheduledExecution && authChecks[AuthConstants.ACTION_READ]}">
                                        <g:link
                                                controller="scheduledExecution"
                                                action="createFromExecution"
                                                params="${[executionId: execution.id]}"
                                                class="action button"
                                                title="Save these Execution parameters as a Job, or run again...">
                                            <g:img file="icon-small-run.png" alt="run" width="16px" height="16px"/>
                                            Run Again or Save &hellip;
                                        </g:link>
                                    </g:if>
                                </g:if>
                            </g:else>
                        </span>
                        </span>
                        </div>

                        <g:set var="isAdhoc" value="${!scheduledExecution}"/>
                        <table>
                        <g:if test="${scheduledExecution}">
                            <tr>
                                <td>
                                    <span class="label">Job:</span>
                                </td>
                                <td>
                                    <g:render template="showJobHead"
                                              model="${[scheduledExecution: scheduledExecution]}"/>
                                </td>
                            </tr>
                        </g:if>
                        <g:if test="${execution.argString}">
                            <tr>
                                <td>
                                    <span class="label">Options:</span>
                                </td>
                                <td>
                                    <span class="argString">${execution?.argString.encodeAsHTML()}</span>
                                </td>
                            </tr>
                        </g:if>
                        <g:if test="${isAdhoc}">
                        %{--<span class="label">Adhoc:</span>--}%
                            <tr>
                                <td >
                                </td>
                                <td>
                                <g:render template="/execution/execDetailsWorkflow"
                                          model="${[workflow: execution.workflow, context: execution, project: execution.project, isAdhoc: isAdhoc]}"/>
                                </td>
                            </tr>
                        </g:if>
                        </table>
                        </td>

                    <td style="vertical-align: top;" width="50%">
                        <div style="">
                        <g:expander key="schedExDetails${scheduledExecution?.id ? scheduledExecution?.id : ''}"
                                    imgfirst="true">Details</g:expander>
                            <div class="presentation" style="display:none" id="schedExDetails${scheduledExecution?.id}">
                                <g:render template="execDetails" model="[execdata: execution,showArgString:false,hideAdhoc: isAdhoc]"/>
                            </div>
                        </div>
                    </td>
                </tr>
            </table>
        </div>
        <div class="clear"></div>
    </div>

  <div id="commandFlow" class="commandFlow">

  <form action="#" id="outputappendform">
      <table width="100%">
          <tr>
              <td >
              </td>
              <td>
                  <div id="progressContainer" class="progressContainer">
                      <div class="progressBar" id="progressBar"
                           title="Progress is an estimate based on average execution time for this ${g.message(code: 'domain.ScheduledExecution.title')}.">0%</div>
                  </div>
              </td>
          %{--</tr>--}%
      %{--</table>--}%
  %{--</div>--}%



    %{--<div id="commandPerformOpts" class="" style="margin: 0 20px;">--}%

        %{--<table width="100%">--}%
            %{--<tr>--}%
                <td class="outputButtons" style="padding:10px; ;text-align: right;">
                    <g:link class="tab ${followmode=='tail'?' selected':''}" style=""
                        title="${g.message(code:'execution.show.mode.Tail.desc')}"
                        controller="execution"  action="show" id="${execution.id}" params="${[lastlines:params.lastlines,mode:'tail'].findAll{it.value}}"><g:message code="execution.show.mode.Tail.title" default="Tail Output"/></g:link>
                    <g:link class="tab ${followmode=='browse'?' selected':''}" style=""
                        title="${g.message(code:'execution.show.mode.Annotated.desc')}"
                        controller="execution"  action="show" id="${execution.id}" params="[mode:'browse']"><g:message code="execution.show.mode.Annotated.title" default="Annotated"/></g:link>
                    <g:link class="tab ${followmode=='node'?' selected':''}" style=""
                        title="${g.message(code:'execution.show.mode.Compact.desc')}"
                        controller="execution"  action="show" id="${execution.id}" params="[mode:'node']"><g:message code="execution.show.mode.Compact.title" default="Compact"/></g:link>
                    
            <span id="fullviewopts" style="${followmode!='browse'?'display:none':''}">

                &nbsp;
                <span
                    class="action textbtn button"
                    title="Click to change"
                    id="ctxcollapseLabel"
                    onclick="followControl.setCollapseCtx($('ctxcollapse').checked);">
                <input
                    type="checkbox"
                    name="ctxcollapse"
                    id="ctxcollapse"
                    value="true"
                    ${followmode=='tail'?'':null==execution?.dateCompleted?'checked="CHECKED"':''}
                    style=""/>
                    <label for="ctxcollapse">Collapse</label>
                </span>

            </span>
            <g:if test="${followmode=='tail'}">
                    Show the last
                    <span class="action textbtn button"
                      title="Click to reduce"
                      onmousedown="followControl.modifyLastlines(-5);return false;">-</span>
                <input
                    type="text"
                    name="lastlines"
                    id="lastlinesvalue"
                    value="${params.lastlines?params.lastlines:defaultLastLines}"
                    size="3"
                    onchange="updateLastlines(this.value)"
                    onkeypress="var x= noenter();if(!x){this.blur();};return x;"
                    style=""/>
                    <span class="action textbtn button"
                      title="Click to increase"
                      onmousedown="followControl.modifyLastlines(5);return false;">+</span>

                    lines
                %{--<span id="taildelaycontrol" style="${execution.dateCompleted?'display:none':''}">,--}%
                    %{--and update every--}%


                    %{--<span class="action textbtn button"--}%
                      %{--title="Click to reduce"--}%
                      %{--onmousedown="followControl.modifyTaildelay(-1);return false;">-</span>--}%
                %{--<input--}%
                    %{--type="text"--}%
                    %{--name="taildelay"--}%
                    %{--id="taildelayvalue"--}%
                    %{--value="1"--}%
                    %{--size="2"--}%
                    %{--onchange="updateTaildelay(this.value)"--}%
                    %{--onkeypress="var x= noenter();if(!x){this.blur();};return x;"--}%
                    %{--style=""/>--}%
                    %{--<span class="action textbtn button"--}%
                      %{--title="Click to increase"--}%
                      %{--onmousedown="followControl.modifyTaildelay(1);return false;">+</span>--}%

                    %{--seconds--}%
                %{--</span>--}%
            </g:if>
                </td>
                <td style="width:120px">
                    <span style="${execution.dateCompleted ? '' : 'display:none'}" class="sepL" id="viewoptionscomplete">
                        <g:link class="action txtbtn" style="padding:5px;"
                            title="Download entire output file" 
                            controller="execution" action="downloadOutput" id="${execution.id}"><img src="${resource(dir:'images',file:'icon-small-file.png')}" alt="Download" title="Download output" width="13px" height="16px"/> <span id="outfilesize">${filesize?filesize+' bytes':''}</span></g:link>
                    </span>
                </td>
            </tr>
            </table>
        </form>
    </div>
    <div id="fileload2" style="display:none;" class="outputdisplayopts"><img src="${resource(dir:'images',file:'icon-tiny-disclosure-waiting.gif')}" alt="Spinner"/> <span id="fileloadpercent"></span></div>
    <div
        id="commandPerform"
        style="display:none; margin: 0 20px; "></div>
    <div id="fileload" style="display:none;" class="outputdisplayopts"><img src="${resource(dir:'images',file:'icon-tiny-disclosure-waiting.gif')}" alt="Spinner"/> <span id="fileload2percent"></span></div>
    <div id="log"></div>
    <g:if test="${scheduledExecution}">
        <div class="runbox">History</div>
        <div class="pageBody">
            <div id="histcontent"></div>
            <g:javascript>
                fireWhenReady('histcontent',loadHistory);
            </g:javascript>
        </div>
    </g:if>
  </body>
</html>


