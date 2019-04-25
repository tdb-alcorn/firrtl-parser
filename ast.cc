
#include "ast.hh"


using namespace FirrtlAst;


Node::Node(NodeType type) {
    this->type = type;
}

std::string FirrtlAst::type2str(NodeType type) {
    switch (type) {
#define X(_t) case(_t): return #_t;
        X(FIRRTL_CIRCUIT)
        X(FIRRTL_MODULE)
        X(FIRRTL_WIRE)
#undef X
    }
}

void FirrtlAst::depthFirstTraversal(Node* root) {
    std::cout << type2str(root->type) << std::endl;
    for (auto child : root->children) {
        FirrtlAst::depthFirstTraversal(child);
    }
}