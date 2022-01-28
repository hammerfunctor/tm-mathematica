#!/bin/env wolframscript

dataBegin=FromCharacterCode[2]
dataEnd=FromCharacterCode[5]

print[s_]:=Print[s]
print[s_List]:=Print@@Flatten[s]
print[s__]:=print[List[s]]
tostring[s_]:=ToString[s]
tostring[s_List]:=StringJoin@@ToString/@Flatten[s]
tostring[s__]:=tostring[List[s]]

markup[key_,params_,delim_:""]={dataBegin,key,delim,params,delim,dataEnd}
latex[params_,delim_:""]:=markup["latex: ",params,delim]
prompt[params_]:=markup["prompt#",params]
verbatim[params_]:=markup["utf8:",params]
ps[params_]:=markup["ps:",params]

inputPrompt[i_:""]:=latex@prompt["\\pink In["<>ToString[i]<>"]:= {}"]

(* Format the output *)
format[out_]:=Switch[out, 
  _Graphics|_Graphics3D, tostring@ps@ExportString[out,"EPS"],
  $Failed,$Failed,
  Null,Null,
  _,tostring@latex[TeXForm[out],"$"]];

repl[s_String]:=Module[{in,out,next},
  in={InputString[s]<>"\n"};
  While[(next=InputString[""])!="EndOfFile",AppendTo[in,next<>"\n"]];
  in=StringJoin[in];
  out=ToExpression[in];
  (*Print[tostring@latex[TeXForm[out],"$"]];*)
  out//format//Print]


repl[tostring[
  verbatim@"Use Wolfram language in GNU TeXmacs
Created by Hammer Hu, implemented in Wolfram, mma by default
Welcome to star and fork it at https://github.com/hammerfunctor/tm-mathematica",
  inputPrompt[1]]]

For[i=2,True,i++,
  repl[tostring@inputPrompt[i]]]
