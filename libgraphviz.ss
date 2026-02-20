;;; -*- Gerbil -*-
;;; Graphviz FFI bindings (libcgraph, libgvc, libcdt)
(export #t)
(import :std/foreign)

(begin-ffi
    (;; Type predicates
     Agraph_t? Agnode_t? Agedge_t? Agsym_t? GVC_t?

     ;; Constants — object kinds
     AGRAPH AGNODE AGEDGE
     ;; Constants — error levels
     AGWARN AGERR AGMAX

     ;; Graph lifecycle
     ffi_agopen_directed ffi_agopen_strict_directed
     ffi_agopen_undirected ffi_agopen_strict_undirected
     agclose agmemread
     agisdirected agisundirected agisstrict agissimple

     ;; Nodes
     agnode agfstnode agnxtnode aglstnode agprvnode
     agdelnode agsubnode agrelabel_node

     ;; Edges
     agedge agfstout agnxtout agfstin agnxtin agfstedge agnxtedge
     agdeledge agsubedge
     ffi_agtail ffi_aghead

     ;; Subgraphs
     agsubg agfstsubg agnxtsubg agparent agdelsubg

     ;; Attributes — typed variants for graph/node/edge
     ffi_agsafeset_graph ffi_agsafeset_node ffi_agsafeset_edge
     ffi_agget_graph ffi_agget_node ffi_agget_edge
     agattr agnxtattr
     ffi_agattrsym_graph ffi_agattrsym_node ffi_agattrsym_edge
     ffi_agxget_graph ffi_agxget_node ffi_agxget_edge
     ffi_agxset_graph ffi_agxset_node ffi_agxset_edge
     ffi_agnameof_graph ffi_agnameof_node ffi_agnameof_edge
     ffi_agsym_name ffi_agsym_defval

     ;; Generic object operations — typed variants
     ffi_agraphof_graph ffi_agraphof_node ffi_agraphof_edge
     ffi_agroot_graph ffi_agroot_node ffi_agroot_edge
     ffi_agcontains_node ffi_agcontains_edge
     ffi_agdelete_node ffi_agdelete_edge
     ffi_agobjkind_graph ffi_agobjkind_node ffi_agobjkind_edge

     ;; Statistics
     agnnodes agnedges agnsubg agdegree agcountuniqedges

     ;; GVC layout and rendering
     gvContext gvFreeContext
     gvLayout gvFreeLayout gvLayoutDone
     gvRenderFilename
     ffi_gvRenderData ffi_gvRenderData_result ffi_gvRenderData_free

     ;; Error handling
     agseterr aglasterr agerrors agreseterrors)

  (declare (not safe))

  (c-declare #<<END-C
#include <graphviz/cgraph.h>
#include <graphviz/gvc.h>

/* --- Finalizers --- */
static ___SCMOBJ ffi_agclose(void *ptr)
{
  agclose((Agraph_t*)ptr);
  return ___FIX(___NO_ERR);
}

static ___SCMOBJ ffi_gvFreeContext(void *ptr)
{
  gvFreeContext((GVC_t*)ptr);
  return ___FIX(___NO_ERR);
}

/* --- agopen shims (Agdesc_t is passed by value) --- */
static Agraph_t* ffi_agopen_directed(char *name)
{
  return agopen(name, Agdirected, NULL);
}

static Agraph_t* ffi_agopen_strict_directed(char *name)
{
  return agopen(name, Agstrictdirected, NULL);
}

static Agraph_t* ffi_agopen_undirected(char *name)
{
  return agopen(name, Agundirected, NULL);
}

static Agraph_t* ffi_agopen_strict_undirected(char *name)
{
  return agopen(name, Agstrictundirected, NULL);
}

/* --- agtail/aghead shims (macros in cgraph.h) --- */
static Agnode_t* ffi_agtail(Agedge_t *e)
{
  return agtail(e);
}

static Agnode_t* ffi_aghead(Agedge_t *e)
{
  return aghead(e);
}

/* --- gvRenderData shim (char** out-param, length unused) --- */
/* graphviz < 13 uses unsigned int*, >= 13 uses size_t*; cast via void* for portability */
static char *_ffi_render_buf = NULL;

static int ffi_gvRenderData(GVC_t *gvc, Agraph_t *g, const char *format)
{
  size_t len = 0;
  if (_ffi_render_buf) { gvFreeRenderData(_ffi_render_buf); _ffi_render_buf = NULL; }
  return gvRenderData(gvc, g, format, &_ffi_render_buf, (void *)&len);
}

static char _ffi_empty[] = "";

static char* ffi_gvRenderData_result(void)
{
  return _ffi_render_buf ? _ffi_render_buf : _ffi_empty;
}

static void ffi_gvRenderData_free(void)
{
  if (_ffi_render_buf) { gvFreeRenderData(_ffi_render_buf); _ffi_render_buf = NULL; }
}

/* --- Agsym_t field accessors --- */
static char _ffi_sym_empty[] = "";

static char* ffi_agsym_name(Agsym_t *sym)
{
  return sym ? sym->name : _ffi_sym_empty;
}

static char* ffi_agsym_defval(Agsym_t *sym)
{
  return sym ? sym->defval : _ffi_sym_empty;
}
END-C
  )

  ;; --- Type predicate macro ---
  (define-macro (define-c-type-predicate pred tag)
    `(define (,pred x)
       (and (##foreign? x)
            (##memq ',tag (foreign-tags x)))))

  ;; --- Pointer types ---

  ;; Root graph — owned, GC calls agclose
  (c-define-type Agraph_t "Agraph_t")
  (c-define-type Agraph_t*
    (pointer Agraph_t (Agraph_t*) "ffi_agclose"))

  ;; Borrowed graph — subgraphs, not freed by GC
  ;; Same tag as Agraph_t* so owned and borrowed are interchangeable
  (c-define-type Agraph_t*/borrowed
    (pointer Agraph_t (Agraph_t*)))

  ;; Nodes — owned by graph, not freed by GC
  (c-define-type Agnode_t "Agnode_t")
  (c-define-type Agnode_t*
    (pointer Agnode_t (Agnode_t*)))

  ;; Edges — owned by graph, not freed by GC
  (c-define-type Agedge_t "Agedge_t")
  (c-define-type Agedge_t*
    (pointer Agedge_t (Agedge_t*)))

  ;; Attribute symbols — owned by graph's attr dict
  (c-define-type Agsym_t "Agsym_t")
  (c-define-type Agsym_t*
    (pointer Agsym_t (Agsym_t*)))

  ;; GVC context — owned, GC calls gvFreeContext
  (c-define-type GVC_t "GVC_t")
  (c-define-type GVC_t*
    (pointer GVC_t (GVC_t*) "ffi_gvFreeContext"))

  ;; --- Type predicates ---
  (define-c-type-predicate Agraph_t? Agraph_t*)
  (define-c-type-predicate Agnode_t? Agnode_t*)
  (define-c-type-predicate Agedge_t? Agedge_t*)
  (define-c-type-predicate Agsym_t? Agsym_t*)
  (define-c-type-predicate GVC_t? GVC_t*)

  ;; --- Constants ---
  (define-const AGRAPH)
  (define-const AGNODE)
  (define-const AGEDGE)
  (define-const AGWARN)
  (define-const AGERR)
  (define-const AGMAX)

  ;; --- Graph lifecycle ---
  (define-c-lambda ffi_agopen_directed (char-string) Agraph_t*
    "ffi_agopen_directed")
  (define-c-lambda ffi_agopen_strict_directed (char-string) Agraph_t*
    "ffi_agopen_strict_directed")
  (define-c-lambda ffi_agopen_undirected (char-string) Agraph_t*
    "ffi_agopen_undirected")
  (define-c-lambda ffi_agopen_strict_undirected (char-string) Agraph_t*
    "ffi_agopen_strict_undirected")

  (define-c-lambda agclose (Agraph_t*) int
    "___return(agclose(___arg1));")
  (define-c-lambda agmemread (char-string) Agraph_t*
    "agmemread")

  (define-c-lambda agisdirected (Agraph_t*/borrowed) int "agisdirected")
  (define-c-lambda agisundirected (Agraph_t*/borrowed) int "agisundirected")
  (define-c-lambda agisstrict (Agraph_t*/borrowed) int "agisstrict")
  (define-c-lambda agissimple (Agraph_t*/borrowed) int "agissimple")

  ;; --- Nodes ---
  (define-c-lambda agnode (Agraph_t*/borrowed char-string int) Agnode_t*
    "agnode")
  (define-c-lambda agfstnode (Agraph_t*/borrowed) Agnode_t*
    "agfstnode")
  (define-c-lambda agnxtnode (Agraph_t*/borrowed Agnode_t*) Agnode_t*
    "agnxtnode")
  (define-c-lambda aglstnode (Agraph_t*/borrowed) Agnode_t*
    "aglstnode")
  (define-c-lambda agprvnode (Agraph_t*/borrowed Agnode_t*) Agnode_t*
    "agprvnode")
  (define-c-lambda agdelnode (Agraph_t*/borrowed Agnode_t*) int
    "agdelnode")
  (define-c-lambda agsubnode (Agraph_t*/borrowed Agnode_t* int) Agnode_t*
    "agsubnode")
  (define-c-lambda agrelabel_node (Agnode_t* char-string) int
    "agrelabel_node")

  ;; --- Edges ---
  (define-c-lambda agedge (Agraph_t*/borrowed Agnode_t* Agnode_t* char-string int) Agedge_t*
    "agedge")
  (define-c-lambda agfstout (Agraph_t*/borrowed Agnode_t*) Agedge_t*
    "agfstout")
  (define-c-lambda agnxtout (Agraph_t*/borrowed Agedge_t*) Agedge_t*
    "agnxtout")
  (define-c-lambda agfstin (Agraph_t*/borrowed Agnode_t*) Agedge_t*
    "agfstin")
  (define-c-lambda agnxtin (Agraph_t*/borrowed Agedge_t*) Agedge_t*
    "agnxtin")
  (define-c-lambda agfstedge (Agraph_t*/borrowed Agnode_t*) Agedge_t*
    "agfstedge")
  (define-c-lambda agnxtedge (Agraph_t*/borrowed Agedge_t* Agnode_t*) Agedge_t*
    "agnxtedge")
  (define-c-lambda agdeledge (Agraph_t*/borrowed Agedge_t*) int
    "agdeledge")
  (define-c-lambda agsubedge (Agraph_t*/borrowed Agedge_t* int) Agedge_t*
    "agsubedge")

  (define-c-lambda ffi_agtail (Agedge_t*) Agnode_t*
    "ffi_agtail")
  (define-c-lambda ffi_aghead (Agedge_t*) Agnode_t*
    "ffi_aghead")

  ;; --- Subgraphs ---
  (define-c-lambda agsubg (Agraph_t*/borrowed char-string int) Agraph_t*/borrowed
    "agsubg")
  (define-c-lambda agfstsubg (Agraph_t*/borrowed) Agraph_t*/borrowed
    "agfstsubg")
  (define-c-lambda agnxtsubg (Agraph_t*/borrowed) Agraph_t*/borrowed
    "agnxtsubg")
  (define-c-lambda agparent (Agraph_t*/borrowed) Agraph_t*/borrowed
    "agparent")
  (define-c-lambda agdelsubg (Agraph_t*/borrowed Agraph_t*/borrowed) int
    "agdelsubg")

  ;; --- Attributes (typed variants for void* functions) ---

  ;; agnameof — graph/node/edge
  (define-c-lambda ffi_agnameof_graph (Agraph_t*/borrowed) char-string
    "___return(agnameof(___arg1));")
  (define-c-lambda ffi_agnameof_node (Agnode_t*) char-string
    "___return(agnameof(___arg1));")
  (define-c-lambda ffi_agnameof_edge (Agedge_t*) char-string
    "___return(agnameof(___arg1));")

  ;; agsafeset — graph/node/edge
  (define-c-lambda ffi_agsafeset_graph (Agraph_t*/borrowed char-string char-string char-string) int
    "___return(agsafeset(___arg1, ___arg2, ___arg3, ___arg4));")
  (define-c-lambda ffi_agsafeset_node (Agnode_t* char-string char-string char-string) int
    "___return(agsafeset(___arg1, ___arg2, ___arg3, ___arg4));")
  (define-c-lambda ffi_agsafeset_edge (Agedge_t* char-string char-string char-string) int
    "___return(agsafeset(___arg1, ___arg2, ___arg3, ___arg4));")

  ;; agget — graph/node/edge
  (define-c-lambda ffi_agget_graph (Agraph_t*/borrowed char-string) char-string
    "___return(agget(___arg1, ___arg2));")
  (define-c-lambda ffi_agget_node (Agnode_t* char-string) char-string
    "___return(agget(___arg1, ___arg2));")
  (define-c-lambda ffi_agget_edge (Agedge_t* char-string) char-string
    "___return(agget(___arg1, ___arg2));")

  ;; agattrsym — graph/node/edge
  (define-c-lambda ffi_agattrsym_graph (Agraph_t*/borrowed char-string) Agsym_t*
    "___return(agattrsym(___arg1, ___arg2));")
  (define-c-lambda ffi_agattrsym_node (Agnode_t* char-string) Agsym_t*
    "___return(agattrsym(___arg1, ___arg2));")
  (define-c-lambda ffi_agattrsym_edge (Agedge_t* char-string) Agsym_t*
    "___return(agattrsym(___arg1, ___arg2));")

  ;; agxget — graph/node/edge
  (define-c-lambda ffi_agxget_graph (Agraph_t*/borrowed Agsym_t*) char-string
    "___return(agxget(___arg1, ___arg2));")
  (define-c-lambda ffi_agxget_node (Agnode_t* Agsym_t*) char-string
    "___return(agxget(___arg1, ___arg2));")
  (define-c-lambda ffi_agxget_edge (Agedge_t* Agsym_t*) char-string
    "___return(agxget(___arg1, ___arg2));")

  ;; agxset — graph/node/edge
  (define-c-lambda ffi_agxset_graph (Agraph_t*/borrowed Agsym_t* char-string) int
    "___return(agxset(___arg1, ___arg2, ___arg3));")
  (define-c-lambda ffi_agxset_node (Agnode_t* Agsym_t* char-string) int
    "___return(agxset(___arg1, ___arg2, ___arg3));")
  (define-c-lambda ffi_agxset_edge (Agedge_t* Agsym_t* char-string) int
    "___return(agxset(___arg1, ___arg2, ___arg3));")

  (define-c-lambda agattr (Agraph_t*/borrowed int char-string char-string) Agsym_t*
    "agattr")
  (define-c-lambda agnxtattr (Agraph_t*/borrowed int Agsym_t*) Agsym_t*
    "agnxtattr")

  (define-c-lambda ffi_agsym_name (Agsym_t*) char-string
    "ffi_agsym_name")
  (define-c-lambda ffi_agsym_defval (Agsym_t*) char-string
    "ffi_agsym_defval")

  ;; --- Generic object operations (typed variants) ---

  ;; agraphof — graph/node/edge
  (define-c-lambda ffi_agraphof_graph (Agraph_t*/borrowed) Agraph_t*/borrowed
    "___return(agraphof(___arg1));")
  (define-c-lambda ffi_agraphof_node (Agnode_t*) Agraph_t*/borrowed
    "___return(agraphof(___arg1));")
  (define-c-lambda ffi_agraphof_edge (Agedge_t*) Agraph_t*/borrowed
    "___return(agraphof(___arg1));")

  ;; agroot — graph/node/edge
  (define-c-lambda ffi_agroot_graph (Agraph_t*/borrowed) Agraph_t*/borrowed
    "___return(agroot(___arg1));")
  (define-c-lambda ffi_agroot_node (Agnode_t*) Agraph_t*/borrowed
    "___return(agroot(___arg1));")
  (define-c-lambda ffi_agroot_edge (Agedge_t*) Agraph_t*/borrowed
    "___return(agroot(___arg1));")

  ;; agcontains — 2nd arg is node or edge
  (define-c-lambda ffi_agcontains_node (Agraph_t*/borrowed Agnode_t*) int
    "___return(agcontains(___arg1, ___arg2));")
  (define-c-lambda ffi_agcontains_edge (Agraph_t*/borrowed Agedge_t*) int
    "___return(agcontains(___arg1, ___arg2));")

  ;; agdelete — 2nd arg is node or edge
  (define-c-lambda ffi_agdelete_node (Agraph_t*/borrowed Agnode_t*) int
    "___return(agdelete(___arg1, ___arg2));")
  (define-c-lambda ffi_agdelete_edge (Agraph_t*/borrowed Agedge_t*) int
    "___return(agdelete(___arg1, ___arg2));")

  ;; agobjkind — graph/node/edge
  (define-c-lambda ffi_agobjkind_graph (Agraph_t*/borrowed) int
    "___return(agobjkind(___arg1));")
  (define-c-lambda ffi_agobjkind_node (Agnode_t*) int
    "___return(agobjkind(___arg1));")
  (define-c-lambda ffi_agobjkind_edge (Agedge_t*) int
    "___return(agobjkind(___arg1));")

  ;; --- Statistics ---
  (define-c-lambda agnnodes (Agraph_t*/borrowed) int "agnnodes")
  (define-c-lambda agnedges (Agraph_t*/borrowed) int "agnedges")
  (define-c-lambda agnsubg (Agraph_t*/borrowed) int "agnsubg")
  (define-c-lambda agdegree (Agraph_t*/borrowed Agnode_t* int int) int "agdegree")
  (define-c-lambda agcountuniqedges (Agraph_t*/borrowed Agnode_t* int int) int "agcountuniqedges")

  ;; --- GVC layout and rendering ---
  (define-c-lambda gvContext () GVC_t*
    "gvContext")
  (define-c-lambda gvFreeContext (GVC_t*) int
    "___return(gvFreeContext(___arg1));")
  (define-c-lambda gvLayout (GVC_t* Agraph_t*/borrowed char-string) int
    "gvLayout")
  (define-c-lambda gvFreeLayout (GVC_t* Agraph_t*/borrowed) int
    "gvFreeLayout")
  (define-c-lambda gvLayoutDone (Agraph_t*/borrowed) bool
    "gvLayoutDone")
  (define-c-lambda gvRenderFilename (GVC_t* Agraph_t*/borrowed char-string char-string) int
    "gvRenderFilename")

  (define-c-lambda ffi_gvRenderData (GVC_t* Agraph_t*/borrowed char-string) int
    "ffi_gvRenderData")
  (define-c-lambda ffi_gvRenderData_result () char-string
    "ffi_gvRenderData_result")
  (define-c-lambda ffi_gvRenderData_free () void
    "ffi_gvRenderData_free")

  ;; --- Error handling ---
  (define-c-lambda agseterr (int) int
    "___return((int)agseterr((agerrlevel_t)___arg1));")
  (define-c-lambda aglasterr () char-string
    "aglasterr")
  (define-c-lambda agerrors () int
    "agerrors")
  (define-c-lambda agreseterrors () int
    "agreseterrors")

) ;; end begin-ffi
