;;; -*- Gerbil -*-
;;; Graphviz high-level Gerbil API
(export
  ;; Graph creation
  make-graph read-dot-string

  ;; Graph predicates
  graph-directed? graph-undirected? graph-strict? graph-simple?

  ;; Node CRUD
  add-node! find-node delete-node! relabel-node!

  ;; Edge CRUD
  add-edge! delete-edge!
  edge-tail edge-head

  ;; Traversal — return Scheme lists
  graph-nodes graph-subgraphs
  node-out-edges node-in-edges node-edges

  ;; Subgraphs
  add-subgraph! find-subgraph delete-subgraph! graph-parent

  ;; Object info
  object-name object-kind graph-of root-graph graph-contains?

  ;; Statistics
  node-count edge-count subgraph-count
  node-degree node-unique-edges

  ;; Attributes
  set-attribute! get-attribute
  declare-attribute! object-attributes

  ;; Layout & Rendering
  with-gvc layout! free-layout!
  render-to-file! render-to-string
  graph->file graph->string

  ;; Re-export type predicates and constants
  Agraph_t? Agnode_t? Agedge_t? GVC_t?
  AGRAPH AGNODE AGEDGE)

(import :gerbil-graphviz/libgraphviz)

;;; ============================================================
;;; Graph creation
;;; ============================================================

(def (make-graph name type: (type 'directed))
  (case type
    ((directed)          (ffi_agopen_directed name))
    ((strict-directed)   (ffi_agopen_strict_directed name))
    ((undirected)        (ffi_agopen_undirected name))
    ((strict-undirected) (ffi_agopen_strict_undirected name))
    (else (error "make-graph: invalid type" type))))

(def (read-dot-string str)
  (let ((g (agmemread str)))
    (when (not g) (error "read-dot-string: failed to parse DOT string"))
    g))

;;; ============================================================
;;; Graph predicates
;;; ============================================================

(def (graph-directed? g)    (not (zero? (agisdirected g))))
(def (graph-undirected? g)  (not (zero? (agisundirected g))))
(def (graph-strict? g)      (not (zero? (agisstrict g))))
(def (graph-simple? g)      (not (zero? (agissimple g))))

;;; ============================================================
;;; Nodes
;;; ============================================================

(def (add-node! g name)
  (agnode g name 1))

(def (find-node g name)
  (agnode g name 0))

(def (delete-node! g n)
  (agdelnode g n))

(def (relabel-node! n new-name)
  (agrelabel_node n new-name))

;;; ============================================================
;;; Edges
;;; ============================================================

(def (add-edge! g tail head name: (name ""))
  (agedge g tail head name 1))

(def (delete-edge! g e)
  (agdeledge g e))

(def (edge-tail e) (ffi_agtail e))
(def (edge-head e) (ffi_aghead e))

;;; ============================================================
;;; Traversal helpers — collect linked-list iterations into lists
;;; ============================================================

(def (graph-nodes g)
  (let loop ((n (agfstnode g)) (acc []))
    (if n
      (loop (agnxtnode g n) (cons n acc))
      (reverse acc))))

(def (node-out-edges g n)
  (let loop ((e (agfstout g n)) (acc []))
    (if e
      (loop (agnxtout g e) (cons e acc))
      (reverse acc))))

(def (node-in-edges g n)
  (let loop ((e (agfstin g n)) (acc []))
    (if e
      (loop (agnxtin g e) (cons e acc))
      (reverse acc))))

(def (node-edges g n)
  (let loop ((e (agfstedge g n)) (acc []))
    (if e
      (loop (agnxtedge g e n) (cons e acc))
      (reverse acc))))

(def (graph-subgraphs g)
  (let loop ((s (agfstsubg g)) (acc []))
    (if s
      (loop (agnxtsubg s) (cons s acc))
      (reverse acc))))

;;; ============================================================
;;; Subgraphs
;;; ============================================================

(def (add-subgraph! g name)
  (agsubg g name 1))

(def (find-subgraph g name)
  (agsubg g name 0))

(def (delete-subgraph! g sub)
  (agdelsubg g sub))

(def (graph-parent g)
  (agparent g))

;;; ============================================================
;;; Object info — dispatch based on type predicates
;;; ============================================================

(def (object-name obj)
  (cond
    ((Agraph_t? obj) (ffi_agnameof_graph obj))
    ((Agnode_t? obj) (ffi_agnameof_node obj))
    ((Agedge_t? obj) (ffi_agnameof_edge obj))
    (else (error "object-name: not a graphviz object" obj))))

(def (object-kind obj)
  (cond
    ((Agraph_t? obj) (ffi_agobjkind_graph obj))
    ((Agnode_t? obj) (ffi_agobjkind_node obj))
    ((Agedge_t? obj) (ffi_agobjkind_edge obj))
    (else (error "object-kind: not a graphviz object" obj))))

(def (graph-of obj)
  (cond
    ((Agraph_t? obj) (ffi_agraphof_graph obj))
    ((Agnode_t? obj) (ffi_agraphof_node obj))
    ((Agedge_t? obj) (ffi_agraphof_edge obj))
    (else (error "graph-of: not a graphviz object" obj))))

(def (root-graph obj)
  (cond
    ((Agraph_t? obj) (ffi_agroot_graph obj))
    ((Agnode_t? obj) (ffi_agroot_node obj))
    ((Agedge_t? obj) (ffi_agroot_edge obj))
    (else (error "root-graph: not a graphviz object" obj))))

(def (graph-contains? g obj)
  (cond
    ((Agnode_t? obj) (not (zero? (ffi_agcontains_node g obj))))
    ((Agedge_t? obj) (not (zero? (ffi_agcontains_edge g obj))))
    (else (error "graph-contains?: not a node or edge" obj))))

;;; ============================================================
;;; Statistics
;;; ============================================================

(def (node-count g)     (agnnodes g))
(def (edge-count g)     (agnedges g))
(def (subgraph-count g) (agnsubg g))

(def (node-degree g n in: (in #t) out: (out #t))
  (agdegree g n (if in 1 0) (if out 1 0)))

(def (node-unique-edges g n in: (in #t) out: (out #t))
  (agcountuniqedges g n (if in 1 0) (if out 1 0)))

;;; ============================================================
;;; Attributes — dispatch based on type predicates
;;; ============================================================

(def (set-attribute! obj name value)
  (cond
    ((Agraph_t? obj) (ffi_agsafeset_graph obj name value ""))
    ((Agnode_t? obj) (ffi_agsafeset_node obj name value ""))
    ((Agedge_t? obj) (ffi_agsafeset_edge obj name value ""))
    (else (error "set-attribute!: not a graphviz object" obj))))

(def (get-attribute obj name)
  (let ((val (cond
               ((Agraph_t? obj) (ffi_agget_graph obj name))
               ((Agnode_t? obj) (ffi_agget_node obj name))
               ((Agedge_t? obj) (ffi_agget_edge obj name))
               (else (error "get-attribute: not a graphviz object" obj)))))
    (if (or (not val) (string=? val ""))
      #f
      val)))

(def (declare-attribute! g kind name default: (default ""))
  (agattr g kind name default))

(def (object-attributes g kind)
  (let loop ((sym (agnxtattr g kind #f)) (acc []))
    (if sym
      (loop (agnxtattr g kind sym)
            (cons (cons (ffi_agsym_name sym) (ffi_agsym_defval sym)) acc))
      (reverse acc))))

;;; ============================================================
;;; Layout & Rendering
;;; ============================================================

(def (with-gvc proc)
  (let ((gvc (gvContext)))
    (try (proc gvc)
      (finally
        (foreign-release! gvc)))))

(def (layout! gvc g engine: (engine "dot"))
  (let ((rc (gvLayout gvc g engine)))
    (unless (zero? rc)
      (error "layout! failed" engine rc))))

(def (free-layout! gvc g)
  (gvFreeLayout gvc g))

(def (render-to-file! gvc g format filename)
  (let ((rc (gvRenderFilename gvc g format filename)))
    (unless (zero? rc)
      (error "render-to-file! failed" format filename rc))))

(def (render-to-string gvc g format)
  (let ((rc (ffi_gvRenderData gvc g format)))
    (unless (zero? rc)
      (error "render-to-string failed" format rc))
    (let ((result (ffi_gvRenderData_result)))
      (ffi_gvRenderData_free)
      result)))

;;; ============================================================
;;; Convenience — all-in-one render
;;; ============================================================

(def (graph->file g filename format: (format "png") engine: (engine "dot"))
  (with-gvc
    (lambda (gvc)
      (layout! gvc g engine: engine)
      (render-to-file! gvc g format filename)
      (free-layout! gvc g))))

(def (graph->string g format: (format "svg") engine: (engine "dot"))
  (with-gvc
    (lambda (gvc)
      (layout! gvc g engine: engine)
      (let ((result (render-to-string gvc g format)))
        (free-layout! gvc g)
        result))))
