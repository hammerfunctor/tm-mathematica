
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
#include <iterator>
#include <ostream>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>
#include <unistd.h>

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
struct OutputItem {
  bool isoutputname;
  std::string content;
};

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


  auto fmt_latex(const unsigned char* s) {
    std::ostringstream o {};
    o << DATA_BEGIN << "latex: " << s << DATA_END;
    return o.str();
  }
  auto fmt_latex(const unsigned char* s, const char* prefix) {
    std::ostringstream o {};
    o << DATA_BEGIN << "latex: " << prefix << s << DATA_END;
    return o.str();
  }
  auto fmt_latex(const unsigned char* s, char delim) {
    std::ostringstream o {};
    o << DATA_BEGIN << "latex: " << delim << s << delim << DATA_END;
    return o.str();
  }

  void put_latex(const char* s) { std::cout << fmt_latex((const unsigned char*)s); }

  auto fmt_ps(const unsigned char* s) {
    // write to file
    std::fstream f;
    std::string fname { "/tmp/mma_eps_" };
    fname.append(std::to_string(getpid()));
    fname.append(".eps");
    f.open(fname, std::ios_base::out); f << s; f.close();

    std::ostringstream o {};
    o << DATA_BEGIN << "file:" << fname << "?width=0.618par" << DATA_END;
    return o.str();
  }

  auto fmt_verbatim(const unsigned char* s) {
    std::ostringstream o {};
    o << DATA_BEGIN << "verbatim: " << s << DATA_END;
    return o.str();
  }
  auto fmt_verbatim(const char* s) { return fmt_verbatim((const unsigned char*)s); }

  auto fmt_prompt(const unsigned char* s) {
    std::ostringstream o {};
    o << DATA_BEGIN << "latex:" << DATA_BEGIN << "prompt#\\pink "
      << s << "{}"
      << DATA_END << DATA_END;
    return o.str();
  }

  void enter_string_expr(const char *s) {
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
    int length, numofchar, onamenumber = 0;
    int pkt;
    const unsigned char* result;
    std::vector<OutputItem> items {};

    do {
      pkt = WSNextPacket(lp);
      std::string content {}; // concat returned string and `\n'

      switch (pkt) {
      case INPUTNAMEPKT:
        WSGetUTF8String(lp, &result, &length, &numofchar);
        items.push_back( {false, fmt_prompt(result)} );
        WSReleaseUTF8String(lp, result, length);
        break;
      case OUTPUTNAMEPKT:
        onamenumber += 1;
        WSGetUTF8String(lp, &result, &length, &numofchar);
        items.push_back( {true, fmt_latex(result,"\\magenta ")} );
        WSReleaseUTF8String(lp, result, length);
        break;
      case RETURNTEXTPKT:
        handle_returntextpkt(items);
        break;
      case TEXTPKT:
        WSGetUTF8String(lp, &result, &length, &numofchar);
        content.append(fmt_verbatim(result));
        // '\n' is already included in the printed string
        //content.push_back('\n');
        items.push_back( {false,content} );
        WSReleaseUTF8String(lp, result, length);
        break;
      case MESSAGEPKT:
        WSNewPacket(lp);
        pkt = WSNextPacket(lp);

        WSGetUTF8String(lp, &result, &length, &numofchar);
        content.append(fmt_latex(result,"\\red "));
        content.push_back('\n');
        items.push_back( {false,content} );
        WSReleaseUTF8String(lp, result, length);
        break;
      case SYNTAXPKT:
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
#endif

      WSNewPacket(lp);
      content.clear();
    } while (pkt!=INPUTNAMEPKT);

    std::cout << DATA_BEGIN << "verbatim:";
    for (auto item : items) {
      if (onamenumber==1 && item.isoutputname) {}
      else { std::cout << item.content; }
    }
    std::cout << DATA_END;
  }

  void handle_returntextpkt(std::vector<OutputItem>& items) {
    int elem, length, numofchar;
    const unsigned char* result;
    std::string content {};

    switch ( (elem=WSGetNext(lp)) ) {
    case WSTKSTR:
      //std::cerr << "WSTKSTR" << std::endl;
      WSGetUTF8String(lp, &result, &length, &numofchar);
      if ( ! memcmp("%!PS", result, 4) ){
        // PS
        content.append(fmt_ps(result));
        content.push_back('\n');
        items.push_back( {false, content} );
      } else {
        // string
        content.append(fmt_latex(result,'$'));
        content.push_back('\n');
        items.push_back( {false, content} );
      }
      WSReleaseUTF8String(lp, result, length);
      break;

    case WSTKSYM:
      //std::cerr << "WSTKSYM" << std::endl;
      WSGetUTF8String(lp, &result, &length, &numofchar);
      if ( ! (memcmp("$Failed", result, 7)) ) {
        // handle Symbol: $Failed
        content.append(fmt_verbatim("$Failed"));
        content.push_back('\n');
        items.push_back( {false,content} );
        //put_verbatim((const unsigned char*)"$Failed");
      } else if ( ! (memcmp("Null", result, 4)) ) {
        // ignore Symbol: Null
      } else {
        // Unexpected symbol
        content.append(fmt_latex(result, "\\red Unexpected symbol returned: "));
        content.push_back('\n');
        items.push_back( {false,content} );
      }
      WSReleaseUTF8String(lp, result, length);
      break;

    default:
      std::ostringstream o {};
      o << DATA_BEGIN << "latex:\\red Unknown data from RETURNPKT: "<<elem << DATA_END << '\n';
      items.push_back( {false, o.str()} );
    }
  }

  void apply_and_remove_magic_lines(std::string& s) {
    std::string::size_type pos = 0;
    std::string::size_type prev = 0;

    while ((pos = s.find('\n', prev)) != std::string::npos) {
      if (s.substr(prev, pos - prev).starts_with('%')) {

        //if (s.substr(prev, pos - prev).find("\%noprefix") != std::string::npos) {
        //  prefix = false;
        // } // else

        // TODO: support some real magic line

        prev = pos + 1;
      } else {
        break;
      }
    }
    s.erase(0, prev);
  }

  void set_preprint() { enter_string_expr(preprint); }
};

int main(int argc, char *argv[]) {
  std::string input;

  WSSession session;
  session.set_preprint();
  session.put_latex("\\red Mathematica within TeXmacs");

  while (1) {
    session.output_to_screen();
    std::cout.flush();

    input.clear();
    std::getline(std::cin, input, '\0');

    //session.apply_and_remove_magic_lines(input);
    session.enter_text_packet(input.c_str());
  }
}
