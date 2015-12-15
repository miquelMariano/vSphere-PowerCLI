' *********************************************************************
' PRTG Custom EXE Sensor, VB Demo Script for UTC Time Retrieval via WMI
' *********************************************************************
' created Feb 2011 for PRTG Network Monitor V8 by Paessler Support Team, www.paessler.com
' This script is Open Source and comes without support and warranty

'************ How it works ***************************************************
' Uses Win32_TimeZone to determine the current bias for local time translation. 
' The bias is the difference between Coordinated Universal Time (UTC) and local time. 
' All translations between UTC and local time are based on the following formula: UTC = local time - bias. 
' Builds a valid UTC Timestring by retrieving date- and timevalues via Win32_UTCTime

'************ Set Your WMI Credentials here ****************
' Leave User and Password blank for local machine

strComputer = "."
strUser = ""
strPassword = ""

strNamespace = "root/cimv2"

Set objLocator = CreateObject("WbemScripting.SWbemLocator")
Set objWMIService = objLocator.ConnectServer(strComputer,strNamespace,strUser,strPassword)

Set objTimeZone = objWMIService.ExecQuery ("SELECT Bias FROM Win32_TimeZone")

For Each colTimeZone in objTimeZone
  intBias = colTimeZone.Bias
Next

Set objUTCTime = objWMIService.ExecQuery ("SELECT * FROM Win32_UTCTime")

For Each colUTCTime in objUTCTime 
  intYear = colUTCTime.Year
  intMonth = colUTCTime.Month
  intDay = colUTCTime.Day
  intHour = colUTCTime.Hour
  intMinute = colUTCTime.Minute
  intSecond = colUTCTime.Second
Next

strTargetDate = intYear

strMonth = intMonth
If Len(strMonth) = 1 Then
 strMonth = "0" & strMonth
End If

strTargetDate = strTargetDate & strMonth

strDay = intDay
If Len(strDay) = 1 Then
 strDay = "0" & strDay
End If

strTargetDate = strTargetDate & strDay

strHour = intHour
If Len(strHour ) = 1 Then
  strHour  = "0" & strHour
End If

strTargetDate = strTargetDate & strHour

strMinute = intMinute
If Len(strMinute ) = 1 Then
  strMinute  = "0" & strMinute
End If

strTargetDate = strTargetDate & strMinute


strSecond = intSecond
If Len(strSecond ) = 1 Then
 strSecond  = "0" & strSecond 
End If


If intBias >= 0 Then
  strTargetDate = strTargetDate & strSecond & ".000000+" & intBias
else
  strTargetDate = strTargetDate & strSecond & ".000000" & intBias
End if


wscript.echo  + intBias & ":" & strTargetDate 
wscript.quit("0")


