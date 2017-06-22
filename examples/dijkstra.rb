#!/usr/bin/env ruby
#
# RUN WITH: bundle exec ruby -I lib examples/dijkstra.rb
#
# Example in Ruby â€“ Dijkstra's algorithm in DCI
# Modified and simplified for a Manhattan geometry with 8 roles
#
# TODO:
# 1. Nice chunking with headers. Data first.
# 2. Use terms from glossary only.
# 3. Get rid of two coordinate systems (street / avenue; west / south)
# 4. Change the single Neighbor into an EastNeighbor and SouthNeighbor again
#
#
# Document on web has a model of the data (domain model), the use case, and
# the algorithm that implements the use case. Put this document in a directory.
# It also has the URLs for the implementations in different implementations
#
# Harmonize the code. I take first step.
#
#
#
#
# Demonstrates an example where:
# - objects of class Node play several roles simultaneously
#   (albeit spread across Contexts: a Node can
#   play the CurrentIntersection in one Context and an Eastern or
#   Southern Neighbor in another)
# - stacked Contexts (to implement recursion)
# - mixed access of objects of Node through different
#   paths of role elaboration (the root is just a node,
#   whereas others play roles)
# - there is a significant pre-existing data structure called
#   a Geometry (plays the Map role) which contains the objects
#   of instance. Where DCI comes in is to ascribe roles to those
#   objects and let them interact with each other to evaluate the
#   minimal path through the network
# - true to core DCI we are almost always concerned about
#   what happens between the objects (paths and distance)
#   rather than in the objects themselves (which have
#   relatively uninteresting properties like "name")
# - equality of nodes is not identity, and several
#   nodes compare equal with each other by standard
#   equality (eql?)
# - returns references to the original data objects
#   in a vector, to describe the resulting path
#
# There are some curiosities
# - east_neighbor and south_neighbor were typographically equivalent,
#   so I folded them into a single role: Neighbor. That type still
#   serves the two original roles
# - Roles are truly scoped to the use case context
# - The Map and Distance_labeled_graph_node roles have to be
#   duplicated in two Contexts. blah blah blah
# - Node inheritance is replaced by injecting two roles
#   into the object
# - Injecting roles no longer adds new fields to existing
#   data objects.
# - There is an intentional call to distance_between while the
#   Context is still extant, but outside the scope of the
#   Context itself. Should that be legal?
# - I have added a tentative_distance_values array to the Context
#   to support the algorithm. Its data are shared across the
#   roles of the CalculateShortestPath Context
# - nearest_unvisited_node_to_target is now a feature of Map,
#   which seems to reflect better coupling than in the old
#   design

# Global boilerplate

def infinity; Float::INFINITY end

module ContextAccessor
  def context
    Thread.current[:context]
  end

  def context=(ctx)
    Thread.current[:context] = ctx
  end

  def execute_in_context
    old_context = self.context
    self.context = self
    result = yield
    self.context = old_context
    result
  end
end


#
# Consider street corners on a Manhattan grid. We want to find the
# minimal path from the most northeast city to the most
# southeast city. Use Dijstra's algorithm
#

# Data classes

Edge = Struct.new(:from, :to)


class Node
  attr_reader :name
  def initialize(n); @name = n end
  def eql? (another_node)
    # Nodes are == equal if they have the same name. This is explicitly
    # defined here to call out the importance of the differnce between
    # object equality and identity
    name == another_node.name
  end
  def == (another_node)
    # Equality used in the Map algorithms is object identity
    super
  end
end


#
# --- Geometry is the interface to the data class that has all
# --- the information about the map. This is kind of silly in Ruby
#

class ManhattanGeometry
  # In the domain model we have a general model of streets and avenues. The notions of
  # an east and south neighbor are not part of the domain model, but are germane to
  # the Dijkstra problem. Though they evaluate to the same thing we use different
  # names to reflect these two different (mental) models of Manhattan streets.

  def east_neighbor_of(a)
    raise RuntimeError, "#{__method__} must be implemented"
  end
  def south_neighbor_of(a)
    raise RuntimeError, "#{__method__} must be implemented"
  end

  attr_reader :nodes, :distances, :root, :destination
end

#
# ---------------- Contexts: the home of the use cases for the example ---------------------
#

#
# -------------- This is the main Context for shortest path calculation ---------------------
#

require 'forwardable'
class CalculateShortestPath
  include ContextAccessor

  # These are handles to to the roles

  attr_reader :path_to,
              :east_neighbor,
              :south_neighbor,
              :path,
              :map,
              :current,
              :destination,
              :tentative_distance_values

  def shortest_path
    result = []
    path.each { |node|
      result << "#{node.name}"
      last_node = node
    };
    result.join(' ')
  end

  def shortest_path_with_distances
    result = []
    last_node = nil
    path.each { |node|
      if last_node != nil; result << "- #{map.distance_between(node, last_node)} -" end
      result << "#{node.name}"
      last_node = node
    };
    result.join(' ')
  end

  # This is a shortcut to information that really belongs in the Map.
  # To keep roles stateless, we hold the Map's unvisited structure in the
  # Context object. We access it as though it were in the map

  attr_reader :unvisited


  # Initialization

  def rebind(origin: origin_node, map: geometries)
    @current = origin
    @map = map
    map.extend Map
    @current.extend CurrentIntersection

    map.nodes.each {
      # All nodes play the role of DistanceLabeledGraphNode. This is not a
      # canonical DCI role, since a proper DCI role designates a unique object
      # in any context. This is a role in the sense of Child being a role, and
      # in a given Context I want to address all the children in the room at once.
      # It works fine as a methodful role, less obviously fine as a methodless
      # role.

      |node| node.extend DistanceLabeledGraphNode
    }

    @east_neighbor = map.east_neighbor_of(origin)
    if east_neighbor != nil
      east_neighbor.extend EastNeighbor
    end

    @south_neighbor = map.south_neighbor_of(origin)
    if south_neighbor != nil
      south_neighbor.extend SouthNeighbor
    end

  end

  # public initialize. It's overloaded so that the public version doesn't
  # have to pass a lot of crap; the initialize method takes care of
  # setting up internal data structures on the first invocation. On
  # recursion we override the defaults

  def initialize(origin: origin_node, destination: target_node, map: geometries, path_vector: nil, unvisited: nil, pathto: nil, tentative_distance_values: nil)
    @destination = destination

    rebind(origin: origin, map: map)

    execute(path_vector, unvisited, pathto, tentative_distance_values)
  end


  # There are eight roles in the algorithm:
  #
  # path_to, which is the interface to whatever accumulates the path
  # current, which is the current intersection in the recursive algorithm
  # east_neighbor, which lies DIRECTLY to the east of current
  # south_neighbor, which is DIRECTLy to its south
  # destination, the target node
  # map, which is the oracle for the geometry
  # tentative_distance_values, which supports the algorithm, and is
  #   owned by the CalculateShortestPath context (it is context data)
  #
  #
  # The algorithm is straight from Wikipedia:
  #
  # http://en.wikipedia.org/wiki/Dijkstra's_algorithm
  #
  # and reads directly from the distance method, below

  module DistanceLabeledGraphNode
    # Access to roles and other Context data
    include ContextAccessor
    extend Forwardable

    def_delegator :context, :tentative_distance_values

    def tentative_distance; tentative_distance_values[self] end
    def set_tentative_distance_to(x); tentative_distance_values[self] = x end
  end

  module CurrentIntersection
    # Access to roles and other Context data
    include ContextAccessor
    extend Forwardable

    def_delegator :'context.map', :unvisited

    def_delegators :context, :south_neighbor, :east_neighbor

    # Role Methods
    def unvisited_neighbors
      [].tap do |array|
        if south_neighbor != nil && unvisited[south_neighbor] == true
          array << south_neighbor
        end
        if east_neighbor != nil && unvisited[east_neighbor] == true
          array << east_neighbor
        end
      end
    end
  end

  # This module serves to provide the methods both for the east_neighbor and south_neighbor roles

  module EastNeighbor
    include ContextAccessor

    def relable_node_as(x)
      if x < self.tentative_distance; self.set_tentative_distance_to(x); return :distance_was_udated
      else return :distance_was_not_udated end
    end
  end

  module SouthNeighbor
    include ContextAccessor

    def relable_node_as(x)
      if x < self.tentative_distance; self.set_tentative_distance_to(x); return :distance_was_udated
      else return :distance_was_not_udated end
    end
  end

  # "Map" as in cartography rather than Computer Science...
  #
  # Map is a DCI role. The role in this example is played by an
  # object representing a particular Manhattan geometry

  module Map

    # Access to roles and other Context data

    include ContextAccessor

    # These data are physically in the Context. There used to be a bit
    # affixed to each node used in the Dijkstra algorithm, but that violated
    # the encapsulation of the node. Data classes should be able to be used
    # unmodified by the DCI framework â€” except for the addition of roles,
    # and it's important that roles be stateless. So we put the data in
    # the Context. However, it is logically associated with the Mpa: think
    # of putting a check mark on the map next to each node, as it is
    # visited. So we put the accessor for the univisted vector here
    def unvisited; context.unvisited end

    # Role Methods

    def distance_between(a, b)
      distances[Edge.new(a, b)]
    end

    def origin; root end

    # These two functions presume always traveling
    # in a southern or easterly direction

    def next_down_the_street_from(x); east_neighbor_of(x) end

    def next_along_the_avenue_from(x); south_neighbor_of(x) end

    def nearest_unvisited_node_to_target
      min = infinity
      selection = nil
      unvisited.each_key { |intersection|
        if unvisited[intersection]
          if intersection.tentative_distance < min
            min = intersection.tentative_distance
            selection = intersection
          end
        end
      }
      selection
    end
  end


  def do_inits(path_vector, unvisited_hash, pathto_hash, tentative_distance_values_hash)

    # The conditional switches between the first and subsequent instances of the
    # recursion (the algorithm is recursive in graph contexts)

    if path_vector.nil?

      # blah
      @tentative_distance_values = Hash.new

      # This is the fundamental data structure for Dijkstra's algorithm, called
      # "Q" in the Wikipedia description. It is a boolean hash that maps a
      # node onto false or true according to whether it has been visited
      @unvisited = Hash.new

      # These initializations are directly from the description of the algorithm
      map.nodes.each { |node| @unvisited[node] = true }
      unvisited.delete(map.origin)
      map.nodes.each { |node| node.set_tentative_distance_to(infinity) }
      map.origin.set_tentative_distance_to(0)

      # The path array is kept in the outermost context and serves to store the
      # return path. Each recurring context may add something to the array along
      # the way. However, because of the nature of the algorithm, individual
      # Context instances don't deliver "partial paths" as partial answers.
      @path = Array.new

      # The path_to map is a local associative array that remembers the
      # arrows between nodes through the array and erases them if we
      # re-label a node with a shorter distance
      @path_to = Hash.new

    else
      @tentative_distance_values = tentative_distance_values_hash
      @unvisited = unvisited_hash
      @path = path_vector
      @path_to = pathto_hash
    end
  end


  # This is the method that does the work. Called from initialize.

  def execute(path_vector, unvisited_hash, pathto_hash, tentative_distance_values_hash)
    execute_in_context do
      do_inits(path_vector, unvisited_hash, pathto_hash, tentative_distance_values_hash)

      # Calculate tentative distances of unvisited neighbors
      unvisited_neighbors = current.unvisited_neighbors

      if unvisited_neighbors != nil
        unvisited_neighbors.each {
          |neighbor|
          net_distance = current.tentative_distance + map.distance_between(current, neighbor)
          if neighbor.relable_node_as(net_distance) == :distance_was_udated
            path_to[neighbor] = current
          end
        }
      end
      unvisited.delete(current)

      # Are we done?

      if map.unvisited.size == 0
        save_path(@path)
      else

        # The next current node is the one with the least distance in the
        # unvisited set

        selection = map.nearest_unvisited_node_to_target

        # Recur
        CalculateShortestPath.new(origin: selection, destination: destination, map: map, path_vector: path, unvisited: unvisited, pathto: path_to, tentative_distance_values: tentative_distance_values)
      end
    end
  end


  def each
    path.each { |node| yield node }
  end

  # This method does a simple traversal of the data structures (following path_to)
  # to build the directed traversal vector for the minimum path

  def save_path(pathVector)
    node = destination
    begin
      pathVector << node
      node = path_to[node]
    end while node != nil
  end

end

# This is the main Context for shortest distance calculation

class CalculateShortestDistance
  include ContextAccessor

  def tentative_distance_values; @tentative_distance_values end
  def path; @path end
  def map; @map end
  def current; @current end
  def destination; @destination end


  module Map
    include ContextAccessor

    def distance_between(a, b); distances[Edge.new(a, b)] end

    # These two functions presume always travelling
    # in a southern or easterly direction

    def next_down_the_street_from(x); east_neighbor_of(x) end

    def next_along_the_avenue_from(x); south_neighbor_of(x) end
  end

  module DistanceLabeledGraphNode
    # Access to roles and other Context data
    include ContextAccessor
    extend Forwardable

    def_delegator :context, :tentative_distance_values

    def tentative_distance; tentative_distance_values[self] end
    def set_tentative_distance_to(x); tentative_distance_values[self] = x end
  end

  def rebind(origin: origin_node, map: geometries)
    @current = origin
    @destination = map.destination
    @map = map
    map.extend Map
    map.nodes.each { |node|
      node.extend DistanceLabeledGraphNode
    }
  end

  def initialize(origin: origin_node, destination: target_node, map: geometries)
    rebind(origin: origin, map: map)
    @tentative_distance_values = Hash.new
  end

  def distance
    execute_in_context do
      @current.set_tentative_distance_to(0)
      @path = CalculateShortestPath.new(origin: current, destination: destination, map: map).path
      retval = 0
      previous_node = nil
      path.reverse_each { |node|
        if previous_node.nil?
          retval = 0
        else
          retval += map.distance_between(previous_node, node)
        end
        previous_node = node
      }
      retval
    end
  end
end

require 'minitest/spec'
require 'minitest/autorun'


#
# --- Here are some test data
#

class ManhattanGeometry1 < ManhattanGeometry
  def initialize
    @nodes = Array.new
    @distances = Hash.new

    names = [ "a", "b", "c", "d", "a", "b", "g", "h", "i"]

    3.times { |i|
      3.times { |j| @nodes << Node.new(names[(i*3)+j]) }
    }

    # Aliases to help set up the grid. Grid is of Manhattan form:
    #
    # a - 2 - b - 3 - c
    #   |   |   |
    #   1   2   1
    #   |   |   |
    # d - 1 - e - 1 - f
    #   |       |
    # 2       4
    #   |       |
    # g - 1 - h - 2 - i
    #
    @root = a = nodes[0]
    b = nodes[1]
    c = nodes[2]
    d = nodes[3]
    e = nodes[4]
    f = nodes[5]
    g = nodes[6]
    h = nodes[7]
    @destination = i = nodes[8]

    9.times { |i|
      9.times { |j|
        distances[Edge.new(nodes[i], nodes[j])] = infinity
      }
    }

    distances.update({
      Edge.new(a, b) => 2,
      Edge.new(b, c) => 3,
      Edge.new(c, f) => 1,
      Edge.new(f, i) => 4,
      Edge.new(b, e) => 2,
      Edge.new(e, f) => 1,
      Edge.new(a, d) => 1,
      Edge.new(d, g) => 2,
      Edge.new(g, h) => 1,
      Edge.new(h, i) => 2,
      Edge.new(d, e) => 1
    })

    @distances.freeze


    @next_down_the_street_from = {
      a => b,
      b => c,
      d => e,
      e => f,
      g => h,
      h => i
    }.freeze

    @next_along_the_avenue_from = {
      a => d,
      b => e,
      c => f,
      d => g,
      f => i
    }.freeze
  end

  def east_neighbor_of(a); @next_down_the_street_from[a] end
  def south_neighbor_of(a); @next_along_the_avenue_from[a] end
end


#
# --- Main Program: example output
#

geometries = ManhattanGeometry1.new
path_calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
distance_calculator = CalculateShortestDistance.new(origin: geometries.root, destination: geometries.destination, map: geometries)
puts "Path is: #{path_calculator.shortest_path}"
puts "distance is #{distance_calculator.distance}"


describe 'dijkstra ManhattanGeometry1' do
  it 'calculates distance' do
    geometries = ManhattanGeometry1.new
    calculator = CalculateShortestDistance.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.distance).must_equal(6)
  end

  it 'displays the shortest path' do
    geometries = ManhattanGeometry1.new
    calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.shortest_path).must_equal("i h g d a")
  end

  it 'displays the shortest path with distance between' do
    geometries = ManhattanGeometry1.new
    calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.shortest_path_with_distances).must_equal("i - 2 - h - 1 - g - 2 - d - 1 - a")
  end
end

class ManhattanGeometry2 < ManhattanGeometry
  def initialize
    names = [ "a", "b", "c", "d", "a", "b", "g", "h", "i", "j", "k"]
    @nodes = Array.new
    11.times { |j| nodes << Node.new(names[j]) }

    # Aliases to help set up the grid. Grid is of Manhattan form:
    #
    # a - 2 - b - 3 - c - 1 - j
    #   |   |   |   |
    #   1   2   1   |
    #   |   |   |   |
    # d - 1 - e - 1 - f   1
    #   |       |   |
    # 2       4   |
    #   |       |   |
    # g - 1 - h - 2 - i - 2 - k
    #
    @root = a = nodes[0]
    b = nodes[1]
    c = nodes[2]
    d = nodes[3]
    e = nodes[4]
    f = nodes[5]
    g = nodes[6]
    h = nodes[7]
    i = nodes[8]
    j = nodes[9]
    @destination = k = nodes[10]

    @distances = Hash.new

    11.times { |i|
      11.times { |j|
        distances[Edge.new(nodes[i], nodes[j])] = infinity
      }
    }

    distances.update({
      Edge.new(a, b) => 2,
      Edge.new(b, c) => 3,
      Edge.new(c, f) => 1,
      Edge.new(f, i) => 4,
      Edge.new(b, e) => 2,
      Edge.new(e, f) => 1,
      Edge.new(a, d) => 1,
      Edge.new(d, g) => 2,
      Edge.new(g, h) => 1,
      Edge.new(h, i) => 2,
      Edge.new(d, e) => 1,
      Edge.new(c, j) => 1,
      Edge.new(j, k) => 1,
      Edge.new(i, k) => 2
    })

    @distances.freeze

    @next_down_the_street_from = {
      a => b,
      b => c,
      c => j,
      d => e,
      e => f,
      g => h,
      h => i,
      i => k
    }.freeze

    @next_along_the_avenue_from = {
      a => d,
      b => e,
      c => f,
      d => g,
      f => i,
      j => k
    }.freeze
  end

  def east_neighbor_of(a); @next_down_the_street_from[a] end
  def south_neighbor_of(a); @next_along_the_avenue_from[a] end
end


geometries = ManhattanGeometry2.new
path_calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
distance_calculator = CalculateShortestDistance.new(origin: geometries.root, destination: geometries.destination, map: geometries)
puts "Path is: #{path_calculator.shortest_path_with_distances}"
puts "distance is #{distance_calculator.distance}"


describe 'dijkstra ManhattanGeometry2' do
  it 'calculates distance' do
    geometries = ManhattanGeometry2.new
    calculator = CalculateShortestDistance.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.distance).must_equal(7)
  end

  it 'displays the shortest path' do
    geometries = ManhattanGeometry2.new
    calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.shortest_path).must_equal("k j c b a")
  end

  it 'displays the shortest path with distance between' do
    geometries = ManhattanGeometry2.new
    calculator = CalculateShortestPath.new(origin: geometries.root, destination: geometries.destination, map: geometries)
    expect(calculator.shortest_path_with_distances).must_equal("k - 1 - j - 1 - c - 3 - b - 2 - a")
  end
end

