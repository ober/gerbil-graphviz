;;; -*- Gerbil -*-
;;; Graphviz bindings test suite
(import :std/test
        :std/os/temporaries
        :gerbil-graphviz/graphviz
        :gerbil-graphviz/libgraphviz)
(export graphviz-test)

(def graphviz-test
  (test-suite "Graphviz bindings"

    (test-case "constants are integers"
      (check (integer? AGRAPH) ? values)
      (check (integer? AGNODE) ? values)
      (check (integer? AGEDGE) ? values)
      (check (integer? AGWARN) ? values)
      (check (integer? AGERR) ? values)
      (check (integer? AGMAX) ? values))

    (test-case "create directed graph"
      (let ((g (make-graph "test")))
        (check (Agraph_t? g) ? values)
        (check (graph-directed? g) ? values)
        (check (not (graph-strict? g)) ? values)))

    (test-case "create strict directed graph"
      (let ((g (make-graph "test" type: 'strict-directed)))
        (check (graph-directed? g) ? values)
        (check (graph-strict? g) ? values)))

    (test-case "create undirected graph"
      (let ((g (make-graph "test" type: 'undirected)))
        (check (graph-undirected? g) ? values)
        (check (not (graph-strict? g)) ? values)))

    (test-case "create strict undirected graph"
      (let ((g (make-graph "test" type: 'strict-undirected)))
        (check (graph-undirected? g) ? values)
        (check (graph-strict? g) ? values)))

    (test-case "add and find nodes"
      (let ((g (make-graph "test")))
        (let ((n1 (add-node! g "A"))
              (n2 (add-node! g "B")))
          (check (Agnode_t? n1) ? values)
          (check (Agnode_t? n2) ? values)
          (check (object-name n1) => "A")
          (check (object-name n2) => "B")
          (check (node-count g) => 2)
          ;; find existing node
          (check (Agnode_t? (find-node g "A")) ? values)
          ;; find non-existing returns #f
          (check (find-node g "Z") => #f))))

    (test-case "node traversal"
      (let ((g (make-graph "test")))
        (add-node! g "A")
        (add-node! g "B")
        (add-node! g "C")
        (let ((nodes (graph-nodes g)))
          (check (length nodes) => 3)
          (check (map object-name nodes) => '("A" "B" "C")))))

    (test-case "delete node"
      (let ((g (make-graph "test")))
        (let ((n (add-node! g "A")))
          (add-node! g "B")
          (check (node-count g) => 2)
          (delete-node! g n)
          (check (node-count g) => 1))))

    (test-case "add edges and check endpoints"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (e (add-edge! g a b name: "e1")))
          (check (Agedge_t? e) ? values)
          (check (edge-count g) => 1)
          (check (object-name (edge-tail e)) => "A")
          (check (object-name (edge-head e)) => "B"))))

    (test-case "edge traversal — out-edges"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (c (add-node! g "C")))
          (add-edge! g a b)
          (add-edge! g a c)
          (let ((out (node-out-edges g a)))
            (check (length out) => 2)))))

    (test-case "edge traversal — in-edges"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (c (add-node! g "C")))
          (add-edge! g a c)
          (add-edge! g b c)
          (let ((in (node-in-edges g c)))
            (check (length in) => 2)))))

    (test-case "delete edge"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (e (add-edge! g a b)))
          (check (edge-count g) => 1)
          (delete-edge! g e)
          (check (edge-count g) => 0))))

    (test-case "attributes on graphs, nodes, edges"
      (let ((g (make-graph "test")))
        ;; graph attribute
        (set-attribute! g "label" "My Graph")
        (check (get-attribute g "label") => "My Graph")
        ;; node attribute
        (let ((n (add-node! g "A")))
          (set-attribute! n "color" "red")
          (check (get-attribute n "color") => "red"))
        ;; edge attribute
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (e (add-edge! g a b)))
          (set-attribute! e "style" "dashed")
          (check (get-attribute e "style") => "dashed"))))

    (test-case "get-attribute returns #f for unset"
      (let ((g (make-graph "test")))
        (let ((n (add-node! g "A")))
          (check (get-attribute n "nonexistent") => #f))))

    (test-case "declare-attribute! and object-attributes"
      (let ((g (make-graph "test")))
        (declare-attribute! g AGNODE "shape" default: "box")
        (let ((attrs (object-attributes g AGNODE)))
          (check (pair? attrs) ? values)
          (check (assoc "shape" attrs) => '("shape" . "box")))))

    (test-case "subgraph creation and traversal"
      (let ((g (make-graph "test")))
        (let ((sg1 (add-subgraph! g "cluster_0"))
              (sg2 (add-subgraph! g "cluster_1")))
          (check (Agraph_t? sg1) ? values)
          (check (subgraph-count g) => 2)
          (let ((subs (graph-subgraphs g)))
            (check (length subs) => 2))
          ;; find subgraph
          (check (Agraph_t? (find-subgraph g "cluster_0")) ? values)
          ;; parent
          (check (Agraph_t? (graph-parent sg1)) ? values))))

    (test-case "parse DOT string"
      (let ((g (read-dot-string "digraph { A -> B -> C }")))
        (check (Agraph_t? g) ? values)
        (check (graph-directed? g) ? values)
        (check (node-count g) => 3)
        (check (edge-count g) => 2)))

    (test-case "render to PNG file"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B")))
          (add-edge! g a b)
          (let ((tmpfile (string-append (make-temporary-file-name "gv-test") ".png")))
            (graph->file g tmpfile format: "png")
            (check (file-exists? tmpfile) ? values)))))

    (test-case "render to SVG string"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B")))
          (add-edge! g a b)
          (let ((svg (graph->string g format: "svg")))
            (check (string? svg) ? values)
            (check (string-contains svg "<svg") ? values)))))

    (test-case "render to DOT string"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B")))
          (add-edge! g a b)
          (let ((dot (graph->string g format: "dot")))
            (check (string? dot) ? values)
            (check (string-contains dot "digraph") ? values)))))

    (test-case "multiple layout engines"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B")))
          (add-edge! g a b)
          ;; test dot, neato, fdp
          (for-each
            (lambda (engine)
              (let ((svg (graph->string g format: "svg" engine: engine)))
                (check (string-contains svg "<svg") ? values)))
            '("dot" "neato" "fdp")))))

    (test-case "with-gvc cleanup"
      (let ((g (make-graph "test")))
        (add-node! g "A")
        ;; with-gvc should complete without error
        (with-gvc
          (lambda (gvc)
            (check (GVC_t? gvc) ? values)
            (layout! gvc g)
            (free-layout! gvc g)))))

    (test-case "object-kind"
      (let ((g (make-graph "test")))
        (let* ((n (add-node! g "A"))
               (m (add-node! g "B"))
               (e (add-edge! g n m)))
          (check (object-kind g) => AGRAPH)
          (check (object-kind n) => AGNODE)
          (check (object-kind e) => AGEDGE))))

    (test-case "node-degree"
      (let ((g (make-graph "test")))
        (let* ((a (add-node! g "A"))
               (b (add-node! g "B"))
               (c (add-node! g "C")))
          (add-edge! g a b)
          (add-edge! g a c)
          (add-edge! g b a)
          ;; A: out=2, in=1
          (check (node-degree g a out: #t in: #f) => 2)
          (check (node-degree g a out: #f in: #t) => 1)
          (check (node-degree g a) => 3))))))

;; helper — check if string contains substring
(def (string-contains haystack needle)
  (let ((hlen (string-length haystack))
        (nlen (string-length needle)))
    (let loop ((i 0))
      (cond
        ((> (+ i nlen) hlen) #f)
        ((string=? (substring haystack i (+ i nlen)) needle) #t)
        (else (loop (+ i 1)))))))
