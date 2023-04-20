#!/bin/env wolframscript

BeginPackage["TeXmacsWolfram`"]
InputPrompt::usage        = "Generate a list of objects to print as input prompt";
Prelude::usage            = "Prelude message";
TmRepl::usage             = "Receive something as prompt, then read-eval-print";
TmFormat::usage           = "Format an expression to an output string";
TmOut1::usage              = "Write arguments to stdout";
InCmdArgs::usage          = "Test if the argument is in command line arguments"
TmMsg::error              = "`1`";
TmMsg::input              = "`1`";

Begin["`Private`"]

(* Constants *)
dataBegin = FromCharacterCode[2];
dataEnd = FromCharacterCode[5];
dataEscape = FromCharacterCode[27];
dataCommand = FromCharacterCode[16];

verbatim = "verbatim:";
texmacs = "texmacs:";

width = "0.618par";

texFmtFunction = TeXForm;

stdout = OutputStream["stdout",1];
stderr = OutputStream["stderr",2];
System`$Messages = { stderr };


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
TmOut1[obj_] := WriteString[stdout, data]
TmOut1[obj_TmObj] := WriteString[stdout, Sequence@@Flatten[tmprep[obj]]]
TmOut1[objs__TmObj] := Map[TmOut1, {objs}]
TmOut1[List[objs__TmObj]] := Map[TmOut1, {objs}]



tmErr[data_] := Message[TmMsg::error, data]
tmErr[TmObj[header_String, data_String]] :=
  Message[TmMsg::error, dataBegin<>header<>data<>dataEnd]
tmErr1[data_] :=
  WriteString[stdout, dataBegin, "latex:\\red ", tmEscape[latexEscape[ToString[data]]], dataEnd]
tmErr1[TmObj[header_String, data_String]] :=
  WriteString[stdout, dataBegin, "latex:\\red ", dataBegin,header,latexEscape[data],dataEnd, dataEnd]


tmBegin[] := WriteString[stdout, dataBegin, verbatim]
tmEnd[] := WriteString[stdout, dataEnd]


InputPrompt[i_] := TmObj["latex:",
                         TmObj["prompt# ","\\pink In[", ToString[i], "]:= {}"]
                   ]

Prelude = {
  TmObj["verbatim:", "Wolfram-lang plugin for GNU ",
        TmObj["texmacs:", "<text|<TeXmacs>>"],"
Created by Hammer Hu, implemented in Wolfram, named mma by default
For more info, see "],
  TmObj["texmacs:", "<hlink|\
https://github.com/hammerfunctor/tm-mathematica.git|\
https://github.com/hammerfunctor/tm-mathematica.git>"]
}

(* Format the output *)

(* glyphs inside svg exported from Graphics are undefined in texmacs. maybe bug of qt *)
(* Align this snippet in emacs: align-regexp [: ]= *)
TmFormat[Null]          = Null
TmFormat[$Failed]       = $Failed
(*TmFormat[g_Graphics]   := fmtImage["EPS", g]*)
(*TmFormat[g_Graphics3D] := fmtImage["SVG", g]*)
(*TmFormat[g_Legended]   := fmtImage["EPS", g]*)
TmFormat[g_Graphics]   := fmtImage["PDF", g]
TmFormat[g_Graphics3D] := fmtImage["PDF", g]
TmFormat[g_Legended]   := fmtImage["PDF", g]
TmFormat[t_]           := TmObj["latex:", "$",ToString[texFmtFunction[t]],"$"]

fmtImage[imgFmt_String, g_] := Module[{sdata,shexdata,tree},
  sdata = ExportString[g,imgFmt];
  ext = Switch[imgFmt,
    "EPS", "eps",
    "SVG", "svg",
    "PDF", "pdf"];
  shexdata = StringJoin[IntegerString[#, 16, 2] & /@ ToCharacterCode[sdata]]; (* pad it to length 2 !!! *)
  (* construct the tree *)
  tree = StringJoin["<image|<tuple|<#",shexdata,">|", CreateUUID["mma-output-"]<>"."<>ext ,">|",width,"|||>"];
  TmObj[texmacs, tmEscape[tree]]
]

magicLine[line_String] /; !StringStartsQ[line,"% "] := line
magicLine[line_String] := Module[{widthRegexSub, w, magicLineParams=<||>},
  (* width *)
  widthRegexSub = RegularExpression["-width\\s+([a-zA-Z0-9.]+)"]->"$1";
  w = StringCases[line, widthRegexSub];
  magicLineParams["width"] = If[Length[w]==0, width,
                                If[NumberQ[ToExpression[w[[1]]]],w[[1]]<>"px",
                                   w[[1]]] ];

  magicLineParams (* An Association *)
]

emptyQ[x_Symbol] := SameQ[x, Null]
emptyQ[x_String] := SameQ[x, ""]
emptyQ[x_] := SameQ[ToString[x], ""]

(* Deal with link *)
(* link = LinkLaunch[First@$CommandLine <> " -wstp"] *)
readToEnd[link_LinkObject] := Module[{out = {}},
  While[LinkReadyQ[link],
    AppendTo[out, LinkRead[link]]];
  out
]
readTillInPkt[link_LinkObject] := Module[{out = {}, next},
  While[! LinkReadyQ[link], Pause[0.05]];
  While[! SameQ[InputNamePacket,
                Head[next = LinkRead[link]]],
    AppendTo[out, next]];
  out
]
handlePkt[TextPacket[cont_]] := TmObj["verbatim:",cont]

InCmdArgs[arg_] := Or[MemberQ[$ScriptCommandLine,arg],MemberQ[$CommandLine,arg]]
tmDebug[input_] := If[InCmdArgs["MMA_DEBUG"], tmErr1[input]];

(* REPL loop *)
TmRepl[] := Module[
  {magicLineResult,widthTemp,next,inbuf={},inStream},
  input = InputString[""];
  (* WriteString[stdout, dataBegin, "latex:\\red ", latexEscape[tmEscape[input]], dataEnd]; *)

  tmDebug[input];

  magicLineResult = magicLine[input];
  Switch[magicLineResult,
    _String,
      AppendTo[inbuf,magicLineResult];
      AppendTo[inbuf,"\n"];
      widthTemp = width;,
    _Association,
      widthTemp = magicLineResult["width"];
    ];

  While[(next=InputString[""]) != "EndOfFile",
    AppendTo[inbuf, next];
    AppendTo[inbuf, "\n"];];
  (* WriteString[stderr, StringJoin[inbuf]]; *)
  inStream = StringToStream[StringJoin[inbuf]];

  tmBegin[];
  Block[{width=widthTemp},
    While[!SameQ[next=Read[inStream],EndOfFile],
      TmOut1[TmFormat[next]];
      If[!emptyQ[next], WriteString[stdout,"\n"]]]];
  tmEnd[];
            ]

End[]

Protect[InputPrompt,Prelude,TmRepl,TmFormat,TmOut1,InCmdArgs]
EndPackage[]

If[InCmdArgs["TEXMACS"],
   TmOut1[Prelude];
   Module[{i=1},
          While[
            True,
            TmOut1[InputPrompt[i]]; (* Print the prompt *)
            TmRepl[];              (* Read input, evaluate and print the output *)
            i++;
          ]
   ],

   While[True,
         ToExpression[Input["Enter:"]]
   ]
]
