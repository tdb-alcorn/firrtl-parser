
#ifndef AST_H
#define AST_H

#include <iostream>
#include <string>
#include <vector>

namespace FirrtlAst {
    enum NodeType {
        FIRRTL_CIRCUIT,
        FIRRTL_MODULE,
        FIRRTL_WIRE,
    };

    struct Node {
        NodeType type;

        std::string str;

        std::vector<Node*> children;

        Node(NodeType type);
    };
    
    std::string type2str(NodeType type);

    void depthFirstTraversal(Node* root);
}

#endif