#!/bin/env wolframscript

dataBegin=FromCharacterCode[2]
dataEnd=FromCharacterCode[5]

print[s_]:=Print[s]
print[s_List]:=Print@@Flatten[s]
print[s__]:=print[List[s]]
tostring[s_]:=ToString[s]
tostring[s_List]:=StringJoin@@ToString/@Flatten[s]
tostring[s__]:=tostring[List[s]]

markup[key_,params_]={dataBegin,key,params,dataEnd}
latex[params_]:=markup["latex:",params]
prompt[params_]:=markup["prompt#",params]
verbatim[params_]:=markup["utf8:",params]

inputPrompt[i_:""]:=latex@prompt["\\pink In["<>ToString[i]<>"]:= {}"]

repl[s_String]:=With[{in=InputString[s]},
  print[in]]

repl[tostring[
  verbatim@"Use Wolfram language in GNU TeXmacs
Created by Hammer Hu, implemented in Wolfram, mma by default
Welcome to star and fork it at https://github.com/hammerfunctor/tm-mathematica",
  inputPrompt[1]]]

For[i=2,True,i++,
  repl[tostring@inputPrompt[i]]]
