from cgitb import reset
from neo4j import GraphDatabase

class Interface:
    def __init__(self, uri, user, password):
        self._driver = GraphDatabase.driver(uri, auth=(user, password), encrypted=False)
        self._driver.verify_connectivity()
        with self._driver.session() as session:
            session.run("CALL gds.graph.project('MyGraph', 'Location', 'TRIP', { relationshipProperties: ['distance'] })")
        

    def close(self):
        self._driver.close()

    def bfs(self, start_node, last_node):
        # TODO: Implement this method
        query = '''MATCH (start:Location {name: $start_node}), (end:Location {name: $last_node})
                    CALL gds.bfs.stream('MyGraph',{
                    sourceNode: id(start),
                    targetNodes: [id(end)],
                    relationshipTypes: ['TRIP']
                    })
                    YIELD path
                    RETURN path
                    '''
        with self._driver.session() as session:
            
            output = session.run(query, start_node=start_node, last_node=last_node)
            result = output.data()
            # paths = []
            # result = []
            # for record in output:
            #     path = [node['name'] for node in record["path"].nodes]
            #     paths.append(path)
            #     result.append(record.values())
            # print(paths)
            
            return result
        # raise NotImplementedError

    def pagerank(self, max_iterations, weight_property):
        # TODO: Implement this method
        query = '''CALL gds.pageRank.stream('MyGraph',
                {maxIterations: $max_iterations, relationshipWeightProperty: $weight_property})
                YIELD nodeId, score
                RETURN gds.util.asNode(nodeId).name AS name, score ORDER BY score DESC'''
        with self._driver.session() as session:
            output = session.run(query, max_iterations=max_iterations, weight_property=weight_property)
            result = output.data()
            # max_rank = {"score" : 0}
            # min_rank = {"score" : float('inf')}
            # for record in output:
            #     if max_rank['score'] < record['score']:
            #         max_rank = {"name": record['name'], "score": record['score']}
            #     if min_rank['score'] > record['score']:
            #         min_rank = {"name": record['name'], "score": record['score']}
            # result = [max_rank, min_rank]  
            return [result[0], result[-1]]

        # raise NotImplementedError

