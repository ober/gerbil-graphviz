#!/usr/bin/env gxi
(import :std/build-script
        :std/make)

(defbuild-script
  `((gxc: "libgraphviz"
          "-cc-options" ,(cppflags "libgvc" "")
          "-ld-options" ,(ldflags "libgvc" "-lgvc -lcgraph -lcdt"))
    "graphviz"))
