#!/bin/env wolframscript

BeginPackage["TeXmacsWolfram`"]

InputPrompt::usage        = "Generate a list of objects to print as input prompt"
InputPromptString::usage  = "Generate a string to print as input prompt"
Prelude::usage            = "Prelude message"
TmRepl::usage             = "Receive something as prompt, then read-eval-print"
TmFormat::usage           = "Format an expression to an output string"

Begin["`Private`"]

dataBegin=FromCharacterCode[2]
dataEnd=FromCharacterCode[5]

width="0.618par"

stdout=OutputStream["stdout",1]
stderr=OutputStream["stderr",2]
System`$Messages={stderr}

tostring[s_]:=ToString[s]
tostring[s_List]:=StringJoin@@ToString/@Flatten[s]
tostring[s__]:=tostring[List[s]]

markup[key_,params_,delim_:""]={dataBegin,key,delim,params,delim,dataEnd}
latex[params_,delim_:""]:=markup["latex: ",params,delim]
prompt[params_]:=markup["prompt#",params]
verbatim[params_]:=markup["utf8:",params]
ps[g_]:=Module[{fname},
  fname=FileNameJoin[{$TemporaryDirectory,"tm_figure_"<>ToString[$SessionID]<>".eps"}];
  Export[fname,g];Pause[0.1];(* Wait for IO *)
  markup["file:",fname<>"?width="<>width]]
svg[g_]:=Module[{fname},
  fname=FileNameJoin[{$TemporaryDirectory,"tm_figure_"<>ToString[$SessionID]<>".svg"}];
  Export[fname,g];Pause[0.1];(* Wait for IO *)
  markup["file:",fname<>"?width="<>width]]

InputPrompt[i_]:=latex@prompt["\\pink In["<>ToString[i]<>"]:= {}"]
InputPromptString[i_] := tostring[InputPrompt[i]]
Prelude = verbatim@"Use Wolfram language in GNU TeXmacs
Created by Hammer Hu, implemented in Wolfram, mma by default
Welcome to star and fork it at https://github.com/hammerfunctor/tm-mathematica"

(* Format the output *)
(* glyphs of svg exported from Graphics are undefined in texmacs. maybe bug of qt *)
TmFormat[Null]                    = Null
TmFormat[$Failed]                 = $Failed
TmFormat[g_Graphics3D]            := tostring@svg@g
TmFormat[g_Graphics]              := tostring@ps@g
TmFormat[g_Legended]              := tostring@ps@g
TmFormat[t_]                      := tostring@latex[TeXForm[t],"$"]

fmtPrint[Null] = Null
fmtPrint[out_] := Print[TmFormat[out]]

magicLine[line_String] /; !StringStartsQ[line,"% "] := {line}
magicLine[line_String] := Module[{widthRegex, w},
  widthRegexSub = RegularExpression["-width\\s+([a-zA-Z0-9.]+)\\s*"]->"$1";
  w = StringCases[line, widthRegexSub];
  Join[{""},w]
]

TmRepl[objs__] := TmRepl[tostring[objs]]
TmRepl[s_String] := Module[{in,out,next},
  magicline = magicLine[InputString[s]<>"\n"];
  in = magicline[[1]];
  in = FixedPoint[If[(next=InputString[""])!="EndOfFile", #<>next<>"\n", #]&, in];
  inStream=StringToStream[in];

  widthTemp = If[Length[magicline]==1, width, magicline[[2]]];
  Block[{width=widthTemp},
    While[!SameQ[next=Read[inStream],EndOfFile],
      fmtPrint[next]]];
  ]

End[]

Protect[InputPrompt,InputPromptString,Prelude,TmRepl,TmFormat]

EndPackage[]

(* Main Loop *)
Module[{i=1},
  For[
    TmRepl[Prelude,InputPrompt[i]]; i++, True, i++,
    TmRepl[InputPromptString[i]]]]
