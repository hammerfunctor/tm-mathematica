<TeXmacs|2.1>

<style|<tuple|mynotes|pine>>

<\body>
  Some examples:

  <\small>
    <\session|mma|default>
      <\output>
        Use Wolfram language in GNU TeXmacs

        Created by Hammer Hu, implemented in Wolfram, mma by default

        Welcome to star and fork it at https://github.com/hammerfunctor/tm-mathematica
      </output>

      <\unfolded-io>
        <with|color|pink|In[2]:= >
      <|unfolded-io>
        Print[Sin[x]]

        Sin[x]
      <|unfolded-io>
        Sin[x]
      </unfolded-io>

      <\unfolded-io>
        <with|color|pink|In[3]:= >
      <|unfolded-io>
        Exp[x]]
      <|unfolded-io>
        $Failed

        <\errput>
          \;

          Read::readt: Invalid input found when reading Exp[x]] from\ 

          \;

          \;

          \ \ \ \ StringToStream[Exp[x]]].

          \;
        </errput>
      </unfolded-io>

      <\unfolded-io>
        <with|color|pink|In[4]:= >
      <|unfolded-io>
        f[x_,y_]:=Sin[x]+Cos[y];

        {D[f[x,y],x], D[f[x,y],y]}
      <|unfolded-io>
        <math|<around|{|cos <around|(|x|)>,-sin <around|(|y|)>|}>>
      </unfolded-io>

      <\unfolded-io>
        <with|color|pink|In[5]:= >
      <|unfolded-io>
        f[x,y]^2
      <|unfolded-io>
        <math|<around|(|sin <around|(|x|)>+cos <around|(|y|)>|)><rsup|2>>
      </unfolded-io>

      <\unfolded-io>
        <with|color|pink|In[6]:= >
      <|unfolded-io>
        Plot3D[f[x,y]^2,{x,-1,1},{y,-1,1}]
      <|unfolded-io>
      </unfolded-io>

      <\unfolded-io>
        <with|color|pink|In[6]:= >
      <|unfolded-io>
        Plot3D[f[x,y]]
      <|unfolded-io>
        <\errput>
          \;

          Plot3D::argr: Plot3D called with 1 argument; 3 arguments are
          expected.
        </errput>
      </unfolded-io>

      <\input>
        <with|color|pink|In[7]:= >
      <|input>
        \;
      </input>
    </session>
  </small>

  So far, most basic operations you want Mathematica to do are implemented.

  <\wide-tabular>
    <tformat|<cwith|1|-1|1|-1|cell-halign|c>|<cwith|1|-1|1|-1|cell-valign|c>|<table|<row|<\cell>
      <center|<small|<\script-input|mma|default>
        % -width 500

        Plot3D[

        {Sqrt[3+4*Cos[y/2]*Cos[x*Sqrt[3]/2] + 2*Cos[y]],

        -Sqrt[3+4*Cos[y/2]*Cos[x*Sqrt[3]/2] + 2*Cos[y]]},

        {x,-2Pi/Sqrt[3],2Pi/Sqrt[3]},

        {y,-2Pi,2Pi},

        Axes-\<gtr\>True,ViewPoint-\<gtr\>{Pi,Pi/4,Pi/10}]
      </script-input|>>>
    </cell>>|<row|<\cell>
      <math|\<Downarrow\>>
    </cell>>|<row|<\cell>
      <center|<small|<\script-output|mma|default>
        % -width 500

        Plot3D[

        {Sqrt[3+4*Cos[y/2]*Cos[x*Sqrt[3]/2] + 2*Cos[y]],

        -Sqrt[3+4*Cos[y/2]*Cos[x*Sqrt[3]/2] + 2*Cos[y]]},

        {x,-2Pi/Sqrt[3],2Pi/Sqrt[3]},

        {y,-2Pi,2Pi},

        Axes-\<gtr\>True,ViewPoint-\<gtr\>{Pi,Pi/4,Pi/10}]
    </cell>>>>
  </wide-tabular>
</body>

<\initial>
  <\collection>
    <associate|magnification|1>
    <associate|page-height|auto>
    <associate|page-medium|paper>
    <associate|page-orientation|landscape>
    <associate|page-screen-margin|true>
    <associate|page-type|a4>
    <associate|page-width|auto>
    <associate|par-columns|2>
  </collection>
</initial>