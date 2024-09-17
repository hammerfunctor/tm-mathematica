#!/bin/env wolframscript

BeginPackage["TeXmacsWolfram`"]
Prelude::usage            = "Print prelude message";
TmRepl::usage             = "Receive something as prompt, then read-eval-print";
TmFormat::usage           = "Format an expression to an output string";
TmOut1::usage             = "Write arguments to stdout";
InCmdArgs::usage          = "Test if the argument is in command line arguments";
TmMsg::error              = "`1`";
TmMsg::input              = "`1`";
(* Export this symbol to remove prefix TeXmacsWolfram`Private` *)
TmHoldExpr::usage         = "With attr HoldAllComplete";

Begin["`Private`"]

(* Constants *)
dataBegin = FromCharacterCode[2];
dataEnd = FromCharacterCode[5];
dataEscape = FromCharacterCode[27];
dataCommand = FromCharacterCode[16];


tmImageWidth = "0.618par";

tmOutputForm = TeXForm;

tmSetting = <|
  "width"->tmImageWidth,
  "debug"->"false"
  |>

tmInputConv = {
  (* RegularExpression["%(\\d*\)"] -> "Out[$1]" *)
}

stdout = OutputStream["stdout",1];
stderr = OutputStream["stderr",2];

(* System`$Messages = { stderr }; *)
System`$Messages = { };

tmLink = LinkLaunch[First[$CommandLine] <> " -wstp"]
LinkRead[tmLink]

SetAttributes[TmHoldExpr, HoldAllComplete]
LinkWrite[tmLink, Unevaluated[EvaluatePacket[TmHoldExpr[e_] := e]]]
LinkRead[tmLink]


(* Unprotect[Out] *)
(* ClearAll[Out] *)
(* Remove[Out] *)
(* Protect[Out] *)




(* Utility functions*)

tmEscape[data_String] := StringReplace[data, {
  dataEscape -> dataEscape <> dataEscape,
  dataBegin -> dataEscape <> dataBegin,
  dataEnd -> dataEscape <> dataEnd}];
latexEscape[data_String] := StringReplace[data, {
  "%" -> "\\%"}]

TmOut[Null] = Null;
TmOut[data_] := WriteString[stdout, data];
TmOut[TmObj[header_String, data_String]] :=
  WriteString[stdout, dataBegin, header, data, dataEnd];
TmOut[TmObj[header_String, List[data__String]]] :=
  WriteString[stdout, dataBegin, header, data, dataEnd];
TmOut[TmObj[header1_String, header2_String, List[data__String]]] :=
  WriteString[stdout, dataBegin, header1, dataBegin, header2, data, dataEnd, dataEnd]
TmOut[objs__TmObj] := Map[TmOut, List[objs]]

(* Possibly eacspe? *)
tmprep[obj_TmObj] := obj //. TmObj[h_, rest__] :> {dataBegin, h, rest, dataEnd};

(* Every single expression return one single well defined object, and that
 cannot be a TmObj. So we can regard all __TmObj and List[__TmObj] as human
 made output. For an Expression from user input to be re-formatted, it has
 to be a single _TmObj or List[__TmObj]]. *)
TmOut1[Null] = Null;
TmOut1[obj_] := WriteString[stdout, obj]
TmOut1[obj_TmObj] := WriteString[stdout, Sequence@@Flatten[tmprep[obj]]]
TmOut1[objs__] := Map[TmOut1, {objs}]
TmOut1[List[objs__TmObj]] := Map[TmOut1, {objs}]



tmErr[data_] := Message[TmMsg::error, data]
tmErr[TmObj[header_String, data_String]] :=
  Message[TmMsg::error, dataBegin<>header<>data<>dataEnd]

tmErr1[data_] :=
  WriteString[stdout, dataBegin, "latex:\\red ", tmEscape[latexEscape[ToString[data]]], dataEnd,
              dataBegin, "verbatim: \n", dataEnd]
tmErr1[TmObj[header_String, data_String]] :=
  WriteString[stdout, dataBegin, "latex:\\red ", dataBegin,header,latexEscape[data],dataEnd, dataEnd,
              dataBegin, "verbatim: \n", dataEnd]


tmBegin[] := WriteString[stdout, dataBegin, "verbatim: "]
tmEnd[] := WriteString[stdout, dataEnd]


InputPrompt[i_] :=
  TmObj["latex:", TmObj["prompt# ","\\pink In[", ToString[i], "]:= {}"]]


Prelude[] := TmOut1[{
  TmObj["verbatim:", "Wolfram-lang plugin for GNU ",
        TmObj["texmacs:", "<text|<TeXmacs>>"],". Created by Hammer Hu, implemented in
Wolfram language. For more info, see "],
  TmObj["texmacs:", "<hlink|\
github.com/hammerfunctor/tm-mathematica.git|\
https://github.com/hammerfunctor/tm-mathematica.git>"]
  }]

(* Format the output *)

(* glyphs inside svg exported from Graphics are undefined in texmacs. maybe bug of qt *)
(* Align this snippet in emacs: align-regexp [: ]= *)
TmFormat[Null] = Null;
TmFormat[$Failed] = $Failed;
(*TmFormat[g_Graphics]   := fmtImage["EPS", g]*)
(*TmFormat[g_Graphics3D] := fmtImage["SVG", g]*)
(*TmFormat[g_Legended]   := fmtImage["EPS", g]*)
TmFormat[g_Graphics]   := fmtImage["PDF", g]
TmFormat[g_Graphics3D] := fmtImage["PDF", g]
TmFormat[g_Legended]   := fmtImage["PDF", g]
TmFormat[t_]           := TmObj["latex:", "$",ToString[t, tmOutputForm],"$"]

fmtImage[imgFmt_String, g_] :=
  Module[
    {sdata,shexdata,tree,ext}
  ,
    sdata = ExportString[g,imgFmt];
    ext = Switch[imgFmt,
                 "EPS", "eps",
                 "SVG", "svg",
                 "PDF", "pdf"];
    shexdata = StringJoin[IntegerString[#, 16, 2] & /@ ToCharacterCode[sdata]]; (* pad it to length 2 !!! *)
    (* construct the tree *)
    tree = StringJoin["<image|<tuple|<#",shexdata,">|",
                      CreateUUID["mma-output-"]<>"."<>ext ,">|",tmImageWidth,"|||>"];
    TmObj["texmacs: ", tmEscape[tree]]
  ]

mlpat = RegularExpression["^\\(\\*\\*\\s*(.*)\\s*\\*\\*\\)$"]


magicLineQ[line_String] := (
  If[And[StringStartsQ[StringTrim[line,RegularExpression["^ *"]],"% "],
         StringContainsQ[line,"-width"]],
     tmErr1["% now represents previous expressions, use `(** width:400px **)' as the magic line"]];
  StringMatchQ[StringTrim@line,mlpat]
  )

magicLine[line_String] :=
  Module[
    {line1, pat, pairs, mlparams=tmSetting},
    line1 = StringCases[StringTrim@line, mlpat -> "$1"][[1]];

    pat = RegularExpression["([a-zA-Z0-9]+)\\s*:\\s*([a-zA-Z0-9.]+)"];
    pairs = StringCases[line1, pat -> {"$1", "$2"}];

    (* set params *)
    (mlparams[#1]=#2)& @@@ pairs;
    (* Print[mlparams]; *)
    mlparams (* An Association *)
  ]

emptyQ[x_Symbol] := SameQ[x, Null]
emptyQ[x_String] := SameQ[x, ""]
emptyQ[x_] := SameQ[ToString[x], ""]

InCmdArgs[arg_] := Or[MemberQ[$ScriptCommandLine,arg], MemberQ[$CommandLine,arg]]
tmDebug[input_] := If[InCmdArgs["MMA_DEBUG"], tmErr1[input]];
tmDebug[debug_, input_] := If[SameQ[debug,"true"], tmErr1[input]];

inputind = 1;


resolvepacket[InputNamePacket[s_]] :=
  (inputind = Interpreter["Number"] @@ StringCases[s,RegularExpression["In\\[(.*)\\]"]->"$1"])

resolvepacket[OutputPair[OutputNamePacket[s_],_[e_]]] :=
  TmOut1[TmObj["latex:\\pink ", onfilter[s,e]],
         TmObj["verbatim:", "\n"]]

resolvepacket[MsgPair[_MessagePacket, TextPacket[t_]]] :=
  tmErr1[t]

resolvepacket[TextPacket[t_]] :=
  TmOut1[t]


flush[inbuf_List, next_String, exprnum_] :=
  Module[
    {inbuf1, buf}
  ,
    (* tmErr1[inbuf]; *)
    inbuf1 = {Sequence @@ inbuf, next, "\n"};
    buf = StringReplace[StringJoin[inbuf1], tmInputConv];
    (* tmDebug["true", buf]; *)
    If[SyntaxQ[buf],
       LinkWrite[tmLink, EnterExpressionPacket[ToExpression[
         buf, StandardForm, TmHoldExpr]]];
       {exprnum + 1, {}}
     ,
       {exprnum, inbuf1}
    ]
  ]

(* REPL loop *)
TmRepl[] :=
  Module[
    {setting, widthTemp, next, inbuf={}, exprnum=0, results={}, debug}
  ,

    TmOut1[InputPrompt[inputind]];
    next = InputString[""];
    (* tmDebug[next]; *)

    If[magicLineQ[next],
       setting=magicLine[next],
       setting=tmSetting;
       {exprnum, inbuf} = flush[inbuf, next, exprnum]];

    (* tmErr1[inbuf]; *)
    widthTemp = setting["width"];
    debug = setting["debug"];

    While[
      (next=InputString[""]) != "EndOfFile",
      {exprnum, inbuf} = flush[inbuf, next, exprnum]];

    (* TODO: informative message *)
    If[Length[inbuf]!=0, Print["Incomplete input!"]];
    (* input ends, now outputs *)
    tmBegin[];

    While[
      exprnum > 0,
      next = LinkRead[tmLink];
      tmDebug[debug, next];
      Switch[
        next,
        _InputNamePacket, exprnum--; AppendTo[results, next],
        _OutputNamePacket, AppendTo[results, OutputPair[next, LinkRead[tmLink]]],
        _MessagePacket, AppendTo[results, MsgPair[next, LinkRead[tmLink]]],
        _TextPacket, AppendTo[results, next]
      ];
    ];

    Block[
      {tmImageWidth=widthTemp,
       onfilter=If[Length[Position[results,OutputNamePacket]]==1,
                   TmFormat[#2]&, {#1,TmFormat[#2]}&]}
    ,
      Do[resolvepacket[r],{r,results}]
    ];
    tmEnd[];
  ]

End[]

Protect[Prelude,TmRepl,TmFormat,TmOut1,InCmdArgs,TmHoldExpr,TmMsg]
EndPackage[]

If[InCmdArgs["TEXMACS"],
   Prelude[]; While[True, TmRepl[]],
   While[True,
         ToExpression[Input["Enter:"]]
   ]
]
