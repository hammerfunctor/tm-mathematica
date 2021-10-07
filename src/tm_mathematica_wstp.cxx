
/******************************************************************************
 * MODULE     : tm_mathematica_wstp.cxx
 * DESCRIPTION: Interface with Mathematica v2
 * COPYRIGHT  : (C) 2005  Andrey Grozin
 * COPYRIGHT  : (C) 2021  Hammer Hu
 *******************************************************************************
 * This software falls under the GNU general public license version 3 or later.
 * It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
 * in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
 ******************************************************************************/

#include "wstp.h"

#include <cstring>
#include <iostream>
#include <sstream>
#include <string>
#include <fstream>

#define LOG_INPUTEXPR 0
#define LOG_PKT 0
#define LOG_RETURNSTRING 0

constexpr auto seg1 =
"With[{tmp=(";
// seg2: input string as an expression
constexpr auto seg3 =
  ")},"
  "Switch[tmp,";
constexpr auto seg4_epshead =
    "_Graphics|_Graphics3D," "ExportString[tmp,\"EPS\"],";
constexpr auto seg5 = 
    "_String,tmp,"
    "$Failed,$Failed,"
    "Null,Null,"
    "_,Print[TeXForm[tmp]]"
  "]"
"]";

/*
 * To fetch useful output from Mathematica, there are basically three ways:
 *
 * 1. some text following a message   => TEXTPKT:WSTKSTR "<error message>"
 * 2. special Head or symbol          => customize output
 * 3. non-special Head or symbol      => TEXTPKT:WSTKSTR "<printed TeXForm>"
 *
 * The last one is rather tender at present.
 *
 * If you find any other Head or symbols worth handling, don't hesitate
 * to make pull requests.
 */

//=========================== main class
class WSSession {

private:
  WSENV ep;
  WSLINK lp;

  void error(void)
  {
    if( WSError(lp) ) {
      std::cerr << "Error detected by WSTP: " << WSErrorMessage(lp) << "." << std::endl;
    } else {
      std::cerr << "Error detected by this program." << std::endl;
    }
    exit(3);
  }

public:
  WSSession()
  {
    int err;

    ep =  WSInitialize( (WSParametersPointer)0);
    if( ep == (WSENV)0) {
      std::cout << "\2verbatim:\\red Initialization of WSTP failed\5" << std::endl;
      WSDeinitialize(ep);
      exit(1);
    }

    lp = WSOpenString( ep, "-linkname \"math -wstp\"", &err);
    if( lp == (WSLINK)0 ) {
      std::cout << "\2verbatim:\\red Link with WSTP failed\5" << std::endl;
      WSClose(lp);
      exit(2);
    } 
  };

  ~WSSession()
  {
    WSClose(lp);
    WSDeinitialize(ep);
  };

  void enter_string(const char *s)
  {
    WSPutFunction(lp, "EvaluatePacket", 1L);
      WSPutFunction(lp, "ToExpression", 1L);
        WSPutString(lp, s);
    WSEndPacket(lp);
    WSFlush(lp);
  }

  void enter_string_with_ctx(const char *s)
  {
    std::ostringstream mathin;
    mathin << seg1 << s << seg3 << seg4_epshead << seg5;

#if LOG_INPUTEXPR
    std::cerr << mathin.str() << std::endl;
#endif

    enter_string(mathin.str().c_str());
  }

  void read_string_to_screen()
  {
    int pkt = INPUTNAMEPKT;

    // for one input, we only need to wrap output in a single `latex`
#if LOG_RETURNSTRING
    std::cout << "\2verbatim:";
#else
    std::cout << "\2latex:";
#endif
  
    // WSReady returns false if the link is just preparing, use it carefully
    while ( (pkt!=RETURNPKT) && (pkt=WSNextPacket(lp)) ) { // go on if last loop didn't return RETURNPKT

      // if (WSError(lp)) error();
      
      if ( (pkt==TEXTPKT) || (pkt==RETURNPKT) || (pkt==MESSAGEPKT) ) {

        switch (pkt) {
        case TEXTPKT:
          handle_text_pkt(0);
          break;

        case RETURNPKT:
          handle_return_pkt();
          break;

        case MESSAGEPKT:
          WSNewPacket(lp);
          if ( (pkt=WSNextPacket(lp))==TEXTPKT ) {
            handle_text_pkt(1);
          } else {
            std::cerr << "Unsupported feature: MESSAGEPKT follows a non-TEXTPKT" << std::endl;
          }
          break;

        default:
          std::cout << "\\red Unknown packet: " << pkt;
        }

        //post
        std::cout << "\n\n";
      }
      WSNewPacket(lp);
    }

  }

  void handle_text_pkt(int ismsg) {
    int elem, length, numchar;
    const unsigned char *result;

#if LOG_PKT
    std::cerr << "\nTEXTPKT: "; std::cout.flush();
#endif

    switch ( (elem=WSGetNext(lp)) ) {

    case WSTKSTR:
#if LOG_PKT
      std::cerr << "WSTKSTR" << std::endl;
#endif

      //WSGetByteString(lp, &result, &length, 0);
      WSGetUTF8String(lp, &result, &length, &numchar);

      if ( !ismsg ) {
        // handle non-message text output
        std::cout << "$\\displaystyle " << result << "$";


      } else {
        // handle message text output
        std::cout << "\\magenta Message:\2verbatim:\n"
                  << result << "\n\5" << "\\magenta Message end.";
//#if DEBUG
//#endif
      }

      WSReleaseUTF8String(lp, result, length);
      //WSReleaseByteString(lp, result, length);
      break;

    default:
      std::cerr << "\\red Unknown data from TEXTPKT: " << elem;
    }
  }


  void handle_return_pkt() {
    int elem, length, numchar;
    const unsigned char *result;

#if LOG_PKT
    std::cerr << "RETURNPKT: "; std::cout.flush();
#endif

    switch ( (elem=WSGetNext(lp)) ) {

    case WSTKSTR:
#if LOG_PKT
      std::cerr << "WSTKSTR" << std::endl;
#endif

      WSGetUTF8String(lp, &result, &length, &numchar);

      if ( ! memcmp("%!PS", result, 4) ){
        // PS
        std::cout << "\2ps:" << result << "\5";

      } else {
        // string
        std::cout << "\2verbatim: " << result << "\5";
      }

      WSReleaseUTF8String(lp, result, length);
      break;

    case WSTKSYM:
#if LOG_PKT
      std::cerr << "WSTKSYM" << std::endl;
#endif

      WSGetUTF8String(lp, &result, &length, &numchar);

      if ( ! (memcmp("$Failed", result, 7)) ) {
        // handle Symbol: $Failed
        std::cout << "\2verbatim:\n$Failed\5";
      } else if ( ! (memcmp("Null", result, 4)) ) {
        // ignore Symbol: Null
      } else {
        // Unexpected symbol
        std::cout << "\\red \2verbatim: Unexpected symbol returned: "
                  << result << "\5";
      }
      WSReleaseUTF8String(lp, result, length);
      break;

    default:
      std::cout << "\\red Unknown data from RETURNPKT: " << elem;
    }
  }
};

int main(int argc, char *argv[]) {
  size_t InNum = 1;
  std::string input;

  WSSession session;

  std::cout << "\2latex:\\red Mathematicas plugin for TeXmacs - A renewed version written in C++"
            << "\2prompt#\\pink In[" << InNum++ << "]:= {}\5\5";
  std::cout.flush();

  while (1) {
    //std::ostringstream output;
    //output << "";
    
    input.clear();
    std::getline(std::cin, input);
    
    session.enter_string_with_ctx(input.c_str());
    session.read_string_to_screen();

    std::cout << "\2prompt#\\pink In[" << InNum++ << "]:= {}\5\5";
    std::cout.flush();

    //std::cout << output.str() << std::endl;
  }

  return 0;
}
