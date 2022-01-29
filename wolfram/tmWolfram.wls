#!/bin/env wolframscript

dataBegin=FromCharacterCode[2]
dataEnd=FromCharacterCode[5]

width="0.618par"

stdout=OutputStream["stdout",1]
stderr=OutputStream["stderr",2]
$Messages={stderr}

tostring[s_]:=ToString[s]
tostring[s_List]:=StringJoin@@ToString/@Flatten[s]
tostring[s__]:=tostring[List[s]]

markup[key_,params_,delim_:""]={dataBegin,key,delim,params,delim,dataEnd}
latex[params_,delim_:""]:=markup["latex: ",params,delim]
prompt[params_]:=markup["prompt#",params]
verbatim[params_]:=markup["utf8:",params]
ps[params_]:=markup["ps:",params]
svg[g_]:=Module[{fname},
  fname=FileNameJoin[{$TemporaryDirectory,"tm_figure_"<>ToString[$SessionID]<>".svg"}];
  Export[fname,g];
  markup["file:",fname<>"?width="<>width]]

inputPrompt[i_:""]:=latex@prompt["\\pink In["<>ToString[i]<>"]:= {}"]

(* Format the output *)
format[Null]                    = Null
format[$Failed]                 = $Failed
format[g_Graphics|g_Graphics3D] := tostring@svg@g
format[t_]                      := tostring@latex[TeXForm[t],"$"]

fmtPrint[Null] = Null
fmtPrint[out_] := Print[format[out]]

magicLine[line_String] /; !StringStartsQ[line,"% "] := {line}
magicLine[line_String] := Module[{widthRegex, w},
  widthRegexSub = RegularExpression["-width\\s+([a-zA-Z0-9.]+)\\s*"]->"$1";
  w = StringCases[line, widthRegexSub];
  Join[{""},w]
]

repl[s_String]:=Module[{in,out,next},
  magicline = magicLine[InputString[s]<>"\n"];
  in = magicline[[1]];
  in = FixedPoint[If[(next=InputString[""])!="EndOfFile", #<>next<>"\n", #]&, in];
  inStream=StringToStream[in];

  widthTemp = If[Length[magicline]==1, width, magicline[[2]]];
  Block[{width=widthTemp},
    While[!SameQ[next=Read[inStream],EndOfFile],
      fmtPrint[next]]]
  ]

(* Main Loop *)
repl[tostring[
  verbatim@"Use Wolfram language in GNU TeXmacs
Created by Hammer Hu, implemented in Wolfram, mma by default
Welcome to star and fork it at https://github.com/hammerfunctor/tm-mathematica",
  inputPrompt[1]]]

For[i=2,True,i++,
  repl[tostring@inputPrompt[i]]]
