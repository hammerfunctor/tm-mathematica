#!/usr/bin/env wolframscript
(* ::Package:: *)

(* ::Input:: *)
(*link=LinkLaunch["math -swtp"]*)


(* ::Input:: *)
(*read[l_]:=FixedPoint[*)
(*If[LinkReadyQ[l],Append[#,LinkRead[l]],#]&,{}]*)
(*writeAndRead[s_]:=(LinkWrite[link,EnterTextPacket[s]];read[link])*)


(* ::Input:: *)
(*writeAndRead["Print[Sin[x]]*)
(*Sin[x]"]*)


(* ::Input:: *)
(*read[link]//Column*)


(* ::Input:: *)
(*LinkWrite[link,EnterTextPacket["Sin[x]*)
(*$Failed*)
(*Plot[Sin[x],{x,-1,1}]"]]*)


(* ::Input:: *)
(*LinkWrite[link,Unevaluated[ToExpression["$PrePrint=Switch[#,\[IndentingNewLine]_Graphics|_Graphics3D,ExportString[#,\"EPS\"],\[IndentingNewLine]_String,#,\[IndentingNewLine]$Failed,$Failed,\[IndentingNewLine]Null,Null,\[IndentingNewLine]_,TeXForm[#]]&;"]]]*)


(* ::Input:: *)
(*LinkWrite[link,Unevaluated[ToExpression["$PrePrint=Switch[#,\[IndentingNewLine]_Graphics|_Graphics3D,ExportString[#,\"EPS\"],\[IndentingNewLine]$Failed,$Failed,\[IndentingNewLine]Null,Null,\[IndentingNewLine]_,TeXForm[#]]&;"]]]*)


(* ::Input:: *)
(*TextForm[Sin[x]]*)


(* ::Input:: *)
(*TextForm[TeXForm[Sin[x]]]*)


(* ::Input:: *)
(*%+1*)


(* ::Input:: *)
(*?*Form*)
