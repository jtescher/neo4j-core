require 'neo4j-core/traversal/filter_predicate'
require 'neo4j-core/traversal/prune_evaluator'
require 'neo4j-core/traversal/rel_expander'
require 'neo4j-core/traversal/traverser'

module Neo4j

  module Core
    # Contains methods that are mixin for Neo4j::Node
    # The builder pattern is used to construct traversals (all methods returns Neo4j::Traversal::Traverser)
    # @see http://github.com/andreasronge/neo4j/wiki/traverser
    # @see http://docs.neo4j.org/chunked/stable/tutorial-traversal-java-api.html
    module Traversal
      include ToJava

      # A more powerful alternative of #outgoing, #incoming and #both method.
      # You can use this method for example to only traverse nodes based on properties on the relationships
      #
      # @example traverse all relationships with a property of age > 5
      #   some_node.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.depth(:all).to_a
      #
      # @yield [node] Used to find out which relationship should be included in the traversal
      # @yieldparam [Neo4j::Node] node the current node from which we can decide which relationship should be traversed
      # @yieldreturn [Enumerable<Neo4j::Relationship>] which relationships should be traversed
      # @return [Neo4j::Core::Traversal::Traverser] a traverser object which can be used to further describe the traversal
      def expand(&expander)
        Traverser.new(self).expander(&expander)
      end


      # Returns the outgoing nodes for this node.
      #
      # @example Find all my friends (nodes of depth 1 of type <tt>friends</tt>)
      #   me.outgoing(:friends).each {|friend| puts friend.name}
      #
      # @example A possible faster way, avoid loading wrapper Ruby classes, instead use raw java neo4j node objects
      #   me.outgoing(:friends).raw.each {|friend| puts friend[:name]}
      #
      # @example Find all my friends and their friends (nodes of depth 1 of type <tt>friends</tt>)
      #   me.outgoing(:friends).depth(2).each {|friend| puts friend[:name]}
      #
      # @example Find all my friends and include my self in the result
      #   me.outgoing(:friends).depth(4).include_start_node.each {...}
      #
      # @example Find all my friends friends friends, etc. at any depth
      #   me.outgoing(:friends).depth(:all).each {...}
      #
      # @example Find all my friends friends but do not include my friends (only depth == 2)
      #   me.outgoing(:friends).depth(2).filter{|path| path.length == 2}
      #
      # @example Find all my friends but 'cut off' some parts of the traversal path
      #   me.outgoing(:friends).depth(42).prune(|path| an_expression_using_path_returning_true_false }
      #
      # @example Find all my friends and work colleges
      #   me.outgoing(:friends).outgoing(:work).each {...}
      #
      # Of course all the methods <tt>outgoing</tt>, <tt>incoming</tt>, <tt>both</tt>, <tt>depth</tt>, <tt>include_start_node</tt>, <tt>filter</tt>, and <tt>prune</tt>, <tt>eval_paths</tt>, <tt>unique</tt> can be combined.
      #
      # @see http://github.com/andreasronge/neo4j/wiki/traverser
      # @param [String, Symbol] type the relationship type
      # @return (see #expand)
      def outgoing(type)
        Traverser.new(self, :outgoing, type)
      end


      # Returns the incoming nodes of given type(s).
      #
      # @param [String, Symbol] type the relationship type
      # @see #outgoing
      # @see http://github.com/andreasronge/neo4j/wiki/traverser
      # @return (see #expand)
      def incoming(type)
        Traverser.new(self, :incoming, type)
      end

      # Returns both incoming and outgoing nodes of given types(s)
      #
      # If a type is not given then it will return all types of relationships.
      #
      # @see #outgoing
      # @return (see #expand)
      def both(type=nil)
        Traverser.new(self, :both, type)
      end


      # Traverse using a block. The block is expected to return one of the following values:
      # * <tt>:exclude_and_continue</tt>
      # * <tt>:exclude_and_prune</tt>
      # * <tt>:include_and_continue</tt>
      # * <tt>:include_and_prune</tt>
      # This value decides if it should continue to traverse and if it should include the node in the traversal result.
      # The block will receive a path argument.
      #
      # @example
      #   @pet0.eval_paths {|path| path.end_node ==  @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_path).depth(:all)
      #
      # ==== See also
      #
      # * How to use - http://neo4j.rubyforge.org/guides/traverser.html
      # * the path parameter - http://api.neo4j.org/1.4/org/neo4j/graphdb/Path.html
      # * the #unique method - if paths should be visit more the once, etc...
      #
      # @return (see #expand)
      def eval_paths(&eval_block)
        Traverser.new(self).eval_paths(&eval_block)
      end

      # Sets uniqueness of nodes or relationships to visit during a traversals.
      #
      # Allowed values
      # * <tt>:node_global</tt>  A node cannot be traversed more than once (default)
      # * <tt>:node_path</tt>  For each returned node there 's a unique path from the start node to it.
      # * <tt>:node_recent</tt>  This is like :node_global, but only guarantees uniqueness among the most recent visited nodes, with a configurable count.
      # * <tt>:none</tt>  No restriction (the user will have to manage it).
      # * <tt>:rel_global</tt>  A relationship cannot be traversed more than once, whereas nodes can.
      # * <tt>:rel_path</tt>  No restriction (the user will have to manage it).
      # * <tt>:rel_recent</tt>  Same as for :node_recent, but for relationships.
      #
      # @param (see Neo4j::Core::Traversal::Traverser#unique)
      # @see example in #eval_paths
      # @see http://docs.neo4j.org/chunked/stable/tutorial-traversal-java-api.html#_uniqueness
      # @return (see #expand)
      def unique(u)
        Traverser.new(self).unique(u)
      end
    end
  end
end
