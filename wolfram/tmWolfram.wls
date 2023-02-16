#!/bin/env wolframscript

BeginPackage["TeXmacsWolfram`"]
InputPrompt::usage        = "Generate a list of objects to print as input prompt";
Prelude::usage            = "Prelude message";
TmRepl::usage             = "Receive something as prompt, then read-eval-print";
TmFormat::usage           = "Format an expression to an output string";
TmOut::usage              = "Write arguments to stdout";
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


tmErr[data_] := Message[TmMsg::error, data]
tmErr[TmObj[header_String, data_String]] :=
  Message[TmMsg::error, dataBegin<>header<>data<>dataEnd]
tmErr1[data_] :=
  WriteString[stdout, dataBegin, "latex:\\red ", tmEscape[latexEscape[ToString[data]]], dataEnd]
tmErr1[TmObj[header_String, data_String]] :=
  WriteString[stdout, dataBegin, "latex:\\red ", dataBegin,header,latexEscape[data],dataEnd, dataEnd]


tmBegin[] := WriteString[stdout, dataBegin, verbatim]
tmEnd[] := WriteString[stdout, dataEnd]


InputPrompt[i_] := TmObj["latex:", "prompt#",
                         {"\\pink In[", ToString[i], "]:= {}"}]

Prelude = Sequence[
  TmObj["verbatim:", "Use Wolfram language in GNU TeXmacs
Created by Hammer Hu, implemented in Wolfram, named mma by default
Star and fork it at "],
  TmObj["texmacs:", "<hlink|\
https://github.com/hammerfunctor/tm-mathematica.git|\
https://github.com/hammerfunctor/tm-mathematica.git>"]
          ]

(* Format the output *)

(* glyphs inside svg exported from Graphics are undefined in texmacs. maybe bug of qt *)
(* Align this snippet in emacs: align-regexp [: ]= *)
TmFormat[Null]          = Null
TmFormat[$Failed]       = $Failed
TmFormat[g_Graphics]   := fmtImage["ps", "EPS", g]
TmFormat[g_Graphics3D] := fmtImage["svg", "SVG", g]
TmFormat[g_Legended]   := fmtImage["ps", "EPS", g]
TmFormat[t_]           := TmObj["latex:", {"$",ToString[texFmtFunction[t]],"$"}]

fmtImage[ext_String, imgFmt_String, g_] := Module[{sdata,shexdata,tree},
  sdata = ExportString[g,imgFmt];
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

tmDebug[input_] := If[MemberQ[$ScriptCommandLine, "MMA_DEBUG"], tmErr1[input]];

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
      TmOut[TmFormat[next]];
      If[!emptyQ[next], WriteString[stdout,"\n"]]]];
  tmEnd[];
            ]

End[]

Protect[InputPrompt,Prelude,TmRepl,TmFormat,TmOut]
EndPackage[]



TmOut[Prelude]
(* Main Loop *)
Module[{i=1},
  While[True,
    TmOut[InputPrompt[i]]; (* Print the prompt *)
    TmRepl[];              (* Read input, evaluate and print the output *)
    i++;
  ]
]
