
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

#include <cstddef>
#include <cstring>
#include <ios>
#include <iostream>
#include <ostream>
#include <sstream>
#include <string>
#include <fstream>

#define LOG_INPUTEXPR 0
#define LOG_PKT 0
#define LOG_RETURNSTRING 0

constexpr auto preprint =
  "$PrePrint=Switch[#,"
    "_Graphics|_Graphics3D,TextForm[ExportString[#,\"EPS\"]],"
  //"String,TextForm[#],"
    "$Failed,$Failed,"
    "Null,Null,"
    "_,TextForm[TeXForm[#]]]&;";

//=========================== main class
class WSSession {

private:
  WSENV ep;
  WSLINK lp;

  constexpr static char DATA_BEGIN = ((char) 2);
  constexpr static char DATA_END = ((char) 5);
  constexpr static char DATA_ESCAPE = ((char) 27);

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
  bool nextnewline = false;
  bool prefix = true;

  WSSession()
  {
    int err;

    ep =  WSInitialize( (WSParametersPointer)0);
    if( ep == (WSENV)0) {
      put_latex("\\red Initialization of WSTP failed");
      WSDeinitialize(ep);
      exit(1);
    }

    lp = WSOpenString( ep, "-linkname \"math -wstp\"", &err);
    if( lp == (WSLINK)0 ) {
      put_latex("\\red Link with WSTP failed");
      WSClose(lp);
      exit(2);
    }
  };

  ~WSSession()
  {
    WSClose(lp);
    WSDeinitialize(ep);
  };

  void put_latex(const unsigned char* s) {
    std::cout << DATA_BEGIN << "latex: "
              << s
              << DATA_END;
  }
  void put_latex(const char* s) { put_latex((const unsigned char*)s); }
  void put_latex(const unsigned char* s, char delim) {
    std::cout << DATA_BEGIN << "latex: "
              << delim << s << delim
              << DATA_END;
  }
  void put_latex(const unsigned char* s, const char* prefix) {
    std::cout << DATA_BEGIN << "latex: "
              << prefix << s
              << DATA_END;
  }
  void put_ps(const unsigned char* s) {
    std::fstream f;
    const char* fname = "/tmp/tm_ps.eps";
    f.open(fname, std::ios_base::out);
    f << s;
    f.close();
    std::cout << DATA_BEGIN << "file:"
              << fname << "?width=0.618par"
              << DATA_END;
    return;

    std::cout << DATA_BEGIN << "latex:" << DATA_BEGIN
              << "ps:" //<< "% -width 0.418par\n"
              << s << "?width=0.418par"
              << DATA_END << DATA_END;
  }
  void put_verbatim(const unsigned char* s) {
    std::cout << DATA_BEGIN << "verbatim: "
              << s
              << DATA_END;
  }
  void put_prompt(const unsigned char* s) {
    std::cout << DATA_BEGIN << "latex:"
              << DATA_BEGIN << "prompt#\\pink "
              << s << "{}"
              << DATA_END
              << DATA_END;
  }

  void enter_string_expr(const char *s)
  {
    WSPutFunction(lp, "ToExpression", 1L);
      WSPutString(lp, s);
    WSEndPacket(lp);
    WSFlush(lp);
  }

  void enter_text_packet(const char* s) {
    WSPutFunction(lp, "EnterTextPacket", 1L);
    WSPutString(lp, s);
    WSEndPacket(lp);
    WSFlush(lp);
  }

  void output_to_screen() {
    int length, numofchar;
    int pkt;
    const unsigned char* result;

    std::cout << DATA_BEGIN << "verbatim:";
    // embed outputs within a single `verbatim' env

    do {
      pkt = WSNextPacket(lp);

      switch (pkt) {
      case INPUTNAMEPKT:
        nextnewline = false;
        WSGetUTF8String(lp, &result, &length, &numofchar);
        put_prompt(result);
        WSReleaseUTF8String(lp, result, length);
        break;
      case OUTPUTNAMEPKT:
        nextnewline = false;
        WSGetUTF8String(lp, &result, &length, &numofchar);
        if (prefix)
          put_latex(result, "\\magenta ");
        WSReleaseUTF8String(lp, result, length);
        break;
      case RETURNTEXTPKT:
        nextnewline = true; // if Null, it will be false. Or true is ok
        handle_returntextpkt();
        //std::cout << "1";
        break;
      case TEXTPKT:
        nextnewline = false; // '\n' is already included in the printed string
        WSGetUTF8String(lp, &result, &length, &numofchar);
        put_verbatim(result);
        WSReleaseUTF8String(lp, result, length);
        break;
      case MESSAGEPKT:
        nextnewline = true;
        WSNewPacket(lp);
        pkt = WSNextPacket(lp);
        WSGetUTF8String(lp, &result, &length, &numofchar);
        put_latex(result, "\\red ");
        WSReleaseUTF8String(lp, result, length);
        break;
      case SYNTAXPKT:
        nextnewline = false;
        break;
      default:
        break;
      }

#if LOG_PKT
      switch (pkt) {
      case INPUTNAMEPKT:
        std::cerr << "INPUTNAMEPKT";
        break;
      case OUTPUTNAMEPKT:
        std::cerr << "OUTPUTNAMEPKT";
        break;
      case RETURNTEXTPKT:
        std::cerr << "RETURNTEXTPKT";
        break;
      case TEXTPKT:
        std::cerr << "TEXTPKT";
        break;
      case MESSAGEPKT:
        std::cerr << "MESSAGEPKT";
        break;
      case RETURNPKT:
        std::cerr << "RETURNPKT";
        break;
      case SYNTAXPKT:
        std::cerr << "SYNTAXPKT";
        break;
      default:
        std::cerr << "Unrecognized: " << pkt;
        break;
      }
      std::cerr << " " << nextnewline << std::endl;
#endif

      WSNewPacket(lp);

      if (nextnewline) { std::cout << '\n'; }
    } while (pkt!=INPUTNAMEPKT);

    std::cout << DATA_END;
  }

  void handle_returntextpkt() {
    int elem, length, numofchar;
    const unsigned char* result;

    switch ( (elem=WSGetNext(lp)) ) {
    case WSTKSTR:
      //std::cerr << "WSTKSTR" << std::endl;
      WSGetUTF8String(lp, &result, &length, &numofchar);
      if ( ! memcmp("%!PS", result, 4) ){
        // PS
        put_ps(result);
      } else {
        // string
        put_latex(result,'$');
      }
      WSReleaseUTF8String(lp, result, length);
      break;

    case WSTKSYM:
      //std::cerr << "WSTKSYM" << std::endl;
      WSGetUTF8String(lp, &result, &length, &numofchar);
      if ( ! (memcmp("$Failed", result, 7)) ) {
        // handle Symbol: $Failed
        put_verbatim((const unsigned char*)"$Failed");
      } else if ( ! (memcmp("Null", result, 4)) ) {
        // ignore Symbol: Null
        nextnewline = false;
      } else {
        // Unexpected symbol
        put_latex(result, "\\red Unexpected symbol returned: ");
      }
      WSReleaseUTF8String(lp, result, length);
      break;

    default:
      std::cout << DATA_BEGIN
                << "latex:\\red Unknown data from RETURNPKT: " << elem
                << DATA_END;
    }
  }

  void apply_and_remove_magic_lines(std::string& s) {
    std::string::size_type pos = 0;
    std::string::size_type prev = 0;
  
    while ((pos = s.find('\n', prev)) != std::string::npos) {
      if (s.substr(prev, pos - prev).starts_with('%')) {

        if (s.substr(prev, pos - prev).find("\%noprefix") != std::string::npos) {
          prefix = false;
        } // else
        prev = pos + 1;
      } else {
        break;
      }
    }
    s.erase(0, prev);
  }

  void set_preprint() { enter_string_expr(preprint); }

  void reset_state() {
    prefix = true;
    nextnewline = false;
  }
};

int main(int argc, char *argv[]) {
  std::string input;

  WSSession session;
  session.set_preprint();
  session.put_latex("\\red Mathematica within TeXmacs");

  while (1) {
    session.output_to_screen();
    std::cout.flush();
    session.reset_state();

    input.clear();
    std::getline(std::cin, input, '\0');

    session.apply_and_remove_magic_lines(input);
    session.enter_text_packet(input.c_str());
  }
}
