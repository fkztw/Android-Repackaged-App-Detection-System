#!/usr/bin/env python2

import sys
import os
import json
import networkx as nx

import matplotlib
# Default use X-window, change it for outputing graphs. Must after import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from networkx.readwrite  import json_graph
from networkx.algorithms import isomorphism


def dump_json(filename):
    with open(filename) as json_file:
        print json.dumps(json.load(json_file), sort_keys = True, indent = 4)

def parse_saaf_json(filename):
    with open(filename) as json_file:
        saaf_json = json.load(json_file)
    #print saaf_json

    G = nx.MultiDiGraph()
    #graphs = []

    i = 0
    for invoke, invoke_info in saaf_json.iteritems():
        for backtrack in invoke_info:
            j = 0
            for node in backtrack:
                node = dict((k.lower(), v) for k, v in node.iteritems())
                node['parent']  = node['parent'] + i
                node['nodeid']  = node['nodeid'] + i
                node['invoke']  = invoke

                new_node = node['nodeid']
                new_edge = (node['parent'], node['nodeid'])

                if not G.has_node(new_node):
                    G.add_node(new_node, attr_dict = node)

                if node['parent'] == i-1:
                    node['parent'] = i
                elif not G.has_edge(*new_edge):
                    G.add_edge(*new_edge)

                j += 1
            i += j

            #print i
            #print G.edges()
            #print json.dumps(json_graph.node_link_data(G), sort_keys = True, indent = 4)
            #print
        #graphs.append(G)

    #return graphs
    return G

def merge_same_node(G):

    same_nodes = {}
    for node in G.nodes(data = True):
        node_attr = node[1]
        same_nodes.setdefault((node_attr['codeline'], node_attr['reg']), []).append(node_attr['nodeid'])
    #print same_nodes

    moved_nodes = {}
    to_be_deleted = []
    for same_nodes_id in same_nodes.values():
        move_to = same_nodes_id[0]

        for node_id in same_nodes_id[1:]:
            moved_nodes[node_id] = move_to
            to_be_deleted.append(node_id)

    for node in G.nodes(data = True):
        node_parent = node[1]['parent']
        node_parent = moved_nodes.get(node_parent, node_parent)
        node[1]['parent'] = node_parent

        node_id = node[1]['nodeid']
        if moved_nodes.has_key(node_id):
            node_id = moved_nodes[node_id]
            node[1]['nodeid'] = node_id

        if node_parent != node_id and not G.has_edge(node_parent, node_id):
            G.add_edge(node_parent, node_id)

    for node in to_be_deleted:
        G.remove_node(node)

    for edge in G.edges():
        source, target = edge
        if type(G.node[target]['parent']) is list:
            G.node[target]['parent'].append(source)
        else:
            G.node[target]['parent'] = [source]
        #print source, target, edge
        #print

    #print G.nodes(data = True)

    return G

def op_match(node1, node2):
    #node1_attr = node1[1]
    #node2_attr = node2[1]

    if node1['opcode'] == node2['opcode']:
        return True
    else:
        return False


def main():

    if len(sys.argv) < 2:
        sys.exit('Usage: %s $json_file' % sys.argv[0])

    if not os.path.exists(sys.argv[1]):
        sys.exit('ERROR: %s was not found!' % sys.argv[1])

    if len(sys.argv) == 2:
        G = merge_same_node(parse_saaf_json(sys.argv[1]))
        nx.draw_graphviz(G, prog = 'dot')
        plt.axis('off')
        plt.savefig("merged_by_networkx.png")
        json.dump(
            json_graph.node_link_data(G),
            open('ford3js.json', 'w'),
            sort_keys = True,
            indent = 4
        )
    if len(sys.argv) == 3:
        G1 = merge_same_node(parse_saaf_json(sys.argv[1]))
        G2 = merge_same_node(parse_saaf_json(sys.argv[2]))
        GM = isomorphism.DiGraphMatcher(G2, G1, node_match = op_match)
        #GM = isomorphism.DiGraphMatcher(G2, G1)
        print GM.is_isomorphic()
        print GM.subgraph_is_isomorphic()
        print GM.mapping

    #G = nx.MultiDiGraph()
    #for x in graphs_data:
    #    G = merge_graph(G, x)
        #print json.dumps(json_graph.node_link_data(G))
        #print '--------'

    #G = nx.disjoint_union(graphs_data1[0], graphs_data1[2])
    #print json.dumps(json_graph.node_link_data(graphs_data1[0]), sort_keys = True, indent = 4)
    #G = nx.compose_all(graphs_data1)

    #print json.dumps(json_graph.node_link_data(G), sort_keys = True, indent = 4)
    #GM = isomorphism.GraphMatcher(graphs_data1[1], graphs_data2[1])

    #print nx.info(G)
    #draw graph
    #nx.draw_shell(G)
    #pos=nx.graphviz_layout(G)
    #nx.draw_graphviz(G)
    #nx.draw_networkx(G)
    #nx.draw_networkx_nodes(G, pos, alpha = 0.5, width = 20)
    #nx.draw_networkx_edges(G, pos, arrows=True)
    #nx.draw_networkx_labels(G, pos, fontsize=14)
    #nx.draw_spectral(graphs_data1[1])
    #nx.draw_networkx_labels(graphs_data1[1], pos=nx.spring_layout(graphs_data1[1]))
    #plt.rcParams['text.usetex'] = False
    #plt.figure(figsize=(8,8))
    #nx.draw_networkx_edges(G,pos,alpha=0.3,width=10, edge_color='m')
    #nx.draw_networkx_nodes(G,pos,node_size=10,node_color='w',alpha=0.4)
    #nx.draw_networkx_edges(G,pos,alpha=0.4,node_size=0,width=5,edge_color='k')
    #nx.draw_networkx_labels(G,pos,fontsize=14)
    #print GM.is_isomorphic()
    #print GM.mapping

    #print nx.connected_components(graphs_data1[1])
    #print isomorphism.could_be_isomorphic(graphs_data1[1], graphs_data2[1])
    #print isomorphism.fast_could_be_isomorphic(graphs_data1[1], graphs_data2[1])
    #print isomorphism.faster_could_be_isomorphic(graphs_data1[1], graphs_data2[1])

    #print graphs_data1
    #dump_json(sys.argv[1])


if __name__ == '__main__':
    main()
